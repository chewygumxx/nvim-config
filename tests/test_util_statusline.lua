#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_statusline.lua
--
--

local statusline = require("util.statusline")
local eq         = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

---@type cgxx.test.helpers
local helpers = dofile("tests/helpers.lua")
local git     = helpers.git

--- Builds this file's repository fixture, on the branch its expected
--- segments name.
---@param opt? { remote?: boolean, subdir?: string, name?: string }
---@return string dir, string file
local fixture = function(opt)
    opt = opt or {}
    return helpers.repo({
        branch = "stl-test",
        remote = opt.remote,
        subdir = opt.subdir,
        name   = opt.name,
    })
end

--- Blocks until bufnr's segment has been resolved and cached.
---@param bufnr integer
---@return nil
local await = function(bufnr)
    local settled = function()
        return vim.b[bufnr].cgxx_statusline ~= nil
    end
    -- Asserted rather than waited out: a segment that never resolves
    -- leaves the cache empty, which several of the assertions below
    -- would otherwise read as a legitimate "nothing to show"
    assert(
        vim.wait(10000, settled, 20),
        "no segment resolved for buffer " .. bufnr
    )
end

--- Loads file into a buffer and blocks until its segment has resolved.
---
--- The first `M.segment` call is a deliberate cache miss that schedules
--- the git work, so the answer only lands a tick later.
---@param file string
---@return integer bufnr, string segment
local resolved = function(file)
    local bufnr = vim.fn.bufadd(file)
    vim.fn.bufload(bufnr)

    statusline.segment(bufnr)
    await(bufnr)
    return bufnr, statusline.segment(bufnr)
end

describe("util.statusline.segment", function()
    ---@type string[]
    local dirs = {}

    after_each(function()
        for _, dir in ipairs(dirs) do
            vim.fn.delete(dir, "rf")
        end
        dirs = {}
    end)

    --- Registers dir for teardown and returns the fixture unchanged.
    ---@param dir  string
    ---@param file string
    ---@return string dir, string file
    local track = function(dir, file)
        dirs[#dirs + 1] = dir
        return dir, file
    end

    it("reports slug, branch and root-relative path", function()
        local _, file    = track(fixture())
        local _, segment = resolved(file)
        eq(segment, "~example-owner/example-repo.git:stl-test:/file.lua")
    end)

    it("keeps the full prefix of a nested file", function()
        local _, file    = track(fixture({ subdir = "sub/dir" }))
        local _, segment = resolved(file)
        eq(
            segment,
            "~example-owner/example-repo.git:stl-test:/sub/dir/file.lua"
        )
    end)

    it("stands in for the slug without an origin remote", function()
        local _, file    = track(fixture({ remote = false }))
        local _, segment = resolved(file)
        eq(segment, "<local>:stl-test:/file.lua")
    end)

    it("stands in for the branch on a detached HEAD", function()
        local dir, file = track(fixture())
        git(dir, "add", "-A")
        git(dir, "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "i")
        git(dir, "checkout", "--quiet", "--detach", "HEAD")

        local _, segment = resolved(file)
        eq(segment, "~example-owner/example-repo.git:detached:/file.lua")
    end)

    it("falls back to a home-relative path outside a repository", function()
        local dir = vim.fn.tempname()
        vim.fn.mkdir(dir, "p")
        dirs[#dirs + 1] = dir
        local file      = dir .. "/file.lua"
        vim.fn.writefile({ "" }, file)

        local _, segment = resolved(file)
        eq(segment, vim.fn.fnamemodify(file, ":~"))
    end)

    it("yields to %f for a nameless buffer", function()
        local bufnr = vim.api.nvim_create_buf(true, false)
        eq(statusline.segment(bufnr), "")
        eq(statusline.fallback(bufnr), "%f")
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("yields to %f for a special buffer", function()
        local _, file = track(fixture())
        local bufnr   = vim.fn.bufadd(file)
        vim.fn.bufload(bufnr)
        vim.bo[bufnr].buftype = "nofile"

        statusline.segment(bufnr)
        await(bufnr)
        eq(vim.b[bufnr].cgxx_statusline, false)
        eq(statusline.segment(bufnr), "")
        eq(statusline.fallback(bufnr), "%f")
    end)

    it("suppresses the %f fallback once a segment resolves", function()
        local _, file = track(fixture())
        local bufnr   = resolved(file)
        eq(statusline.fallback(bufnr), "")
    end)

    it("resolves the name the buffer has when the work starts", function()
        local _, file = track(fixture())
        local bufnr   = vim.fn.bufadd(file)
        vim.fn.bufload(bufnr)

        -- A cache miss only *schedules* the resolve, so a rename landing
        -- in the same tick is picked up before any git call is issued.
        -- What happens to an answer already in flight is a separate
        -- question, and a real race: see "util.statusline in flight".
        statusline.segment(bufnr)
        local _, renamed = track(fixture({ name = "elsewhere.lua" }))
        vim.api.nvim_buf_set_name(bufnr, renamed)

        statusline.segment(bufnr)
        await(bufnr)
        eq(statusline.segment(bufnr):find("elsewhere.lua") ~= nil, true)
    end)

    it("re-resolves after refresh", function()
        local dir, file = track(fixture())
        local bufnr     = resolved(file)

        git(dir, "branch", "-M", "renamed")
        statusline.refresh(bufnr)
        eq(vim.b[bufnr].cgxx_statusline, nil)

        statusline.segment(bufnr)
        await(bufnr)
        eq(
            statusline.segment(bufnr),
            "~example-owner/example-repo.git:renamed:/file.lua"
        )
    end)
end)

--- One held git call: the name it was issued for, and the callback that
--- answers it whenever the test decides to.
---@class cgxx.test.inflight
---@field name    string                         Name the call resolves
---@field resolve fun(info: cgxx.git.info?): nil Answers the call

describe("util.statusline in flight", function()
    -- Every case here is about *when* an answer lands rather than what it
    -- says, so `util.git.info` is replaced by a queue the test drains in
    -- the order it chooses. Real git calls resolve in milliseconds and
    -- always in issue order, which is precisely why the two guards these
    -- cases cover cannot be reached with a real one.
    local util_git = require("util.git")

    ---@type fun(file: string?, callback: fun(info: cgxx.git.info?)): nil
    local real_info

    ---@type cgxx.test.inflight[]
    local calls

    ---@type integer[]
    local bufs

    before_each(function()
        calls     = {}
        bufs      = {}
        real_info = util_git.info
        ---@diagnostic disable-next-line: duplicate-set-field
        util_git.info = function(file, callback)
            calls[#calls + 1] = { name = file or "", resolve = callback }
        end
    end)

    after_each(function()
        util_git.info = real_info
        for _, bufnr in ipairs(bufs) do
            if vim.api.nvim_buf_is_valid(bufnr) then
                vim.api.nvim_buf_delete(bufnr, { force = true })
            end
        end
    end)

    --- Loads path into a buffer registered for teardown. The file need
    --- not exist: nothing here reaches git or the disk.
    ---@param path string
    ---@return integer bufnr
    local opened = function(path)
        local bufnr = vim.fn.bufadd(path)
        vim.fn.bufload(bufnr)
        bufs[#bufs + 1] = bufnr
        return bufnr
    end

    --- Asks for bufnr's segment and returns the git call it started.
    ---
    --- The resolve is scheduled rather than immediate, so the queue only
    --- grows once the event loop has turned; `vim.wait` is what turns it.
    ---@param bufnr integer
    ---@return cgxx.test.inflight call
    local started = function(bufnr)
        local before = #calls
        statusline.segment(bufnr)

        local arrived = function()
            return #calls > before
        end
        assert(vim.wait(1000, arrived, 5), "no git call was started")
        return calls[#calls]
    end

    --- A repository-less answer, as `util.git.info` would report one for
    --- a file at the root of a checkout with no "origin" remote.
    ---@return cgxx.git.info info
    local answer = function()
        return { prefix = "", branch = "stl-test", slug = nil }
    end

    it("invalidates every loaded buffer on a global change", function()
        -- `M.refresh_all` is for a change of git state that belongs to
        -- the checkout rather than to one buffer, ie. someone running
        -- `git checkout` in another terminal
        local one = opened(vim.fn.tempname() .. "/one.lua")
        local two = opened(vim.fn.tempname() .. "/two.lua")

        started(one).resolve(answer())
        started(two).resolve(answer())
        eq(vim.b[one].cgxx_statusline, "<local>:stl-test:/one.lua")
        eq(vim.b[two].cgxx_statusline, "<local>:stl-test:/two.lua")

        statusline.refresh_all()
        eq(vim.b[one].cgxx_statusline, nil)
        eq(vim.b[two].cgxx_statusline, nil)
    end)

    it("drops an answer invalidated by a refresh", function()
        local bufnr = opened(vim.fn.tempname() .. "/file.lua")
        local call  = started(bufnr)

        -- A checkout in another terminal is what `M.refresh_all` reacts
        -- to, and it changes the branch without changing any buffer's
        -- name. The answer already in flight was composed against the
        -- old branch, so it is stale despite naming the right file, and
        -- only the in-flight marker records that.
        statusline.refresh(bufnr)
        call.resolve(answer())

        eq(vim.b[bufnr].cgxx_statusline, nil)
    end)

    it("drops an answer for a name the buffer no longer has", function()
        local bufnr = opened(vim.fn.tempname() .. "/old.lua")
        local call  = started(bufnr)

        -- Renamed with the call already issued and no refresh in
        -- between, so the in-flight marker still matches: the buffer's
        -- current name is the only thing left that can tell this answer
        -- is about a file this buffer no longer shows
        vim.api.nvim_buf_set_name(bufnr, vim.fn.tempname() .. "/new.lua")
        call.resolve(answer())

        eq(vim.b[bufnr].cgxx_statusline, nil)
    end)

    it("keeps the newer answer when a rename supersedes one", function()
        local bufnr = opened(vim.fn.tempname() .. "/old.lua")
        local first = started(bufnr)

        local new = vim.fn.tempname() .. "/new.lua"
        vim.api.nvim_buf_set_name(bufnr, new)
        -- What `BufFilePost` does in a real session, see
        -- "util.statusline.autocmd"
        statusline.refresh(bufnr)
        local second = started(bufnr)

        eq(first.name ~= second.name, true)
        eq(second.name, new)

        -- Out of order on purpose: the newer answer lands first, then the
        -- stale one, which must not overwrite it
        second.resolve(answer())
        first.resolve(answer())

        eq(vim.b[bufnr].cgxx_statusline, "<local>:stl-test:/new.lua")
    end)

    it("invalidates a renamed buffer from its own autocmd", function()
        -- The registration `M.refresh` is called by hand above; without
        -- it a rename leaves the old segment cached until something else
        -- happens to invalidate it
        statusline.autocmd()
        local bufnr = opened(vim.fn.tempname() .. "/old.lua")
        started(bufnr).resolve(answer())
        eq(vim.b[bufnr].cgxx_statusline, "<local>:stl-test:/old.lua")

        vim.api.nvim_buf_set_name(bufnr, vim.fn.tempname() .. "/new.lua")
        eq(vim.b[bufnr].cgxx_statusline, nil)

        vim.api.nvim_create_augroup("cgxx.statusline", { clear = true })
    end)

    it("invalidates every buffer when focus returns", function()
        -- How the branch usually goes stale: a checkout in another
        -- terminal while this session was in the background
        statusline.autocmd()
        local bufnr = opened(vim.fn.tempname() .. "/file.lua")
        started(bufnr).resolve(answer())

        vim.api.nvim_exec_autocmds("FocusGained", {})
        eq(vim.b[bufnr].cgxx_statusline, nil)

        vim.api.nvim_create_augroup("cgxx.statusline", { clear = true })
    end)
end)

describe("util.statusline.value", function()
    ---@type string
    local original

    ---@type string[]
    local dirs = {}

    before_each(function()
        original = vim.o.statusline
        statusline.setup()
    end)

    after_each(function()
        vim.o.statusline = original
        for _, dir in ipairs(dirs) do
            vim.fn.delete(dir, "rf")
        end
        dirs = {}
    end)

    --- Renders the live 'statusline' for winid.
    ---
    --- `maxwidth` rather than a real window size: a split of the default
    --- 80 columns is narrower than these segments and the leading `%<`
    --- would truncate them, while a headless UI ignores 'columns'.
    ---@param winid?    integer Default: current window
    ---@param maxwidth? integer Default: 200
    ---@return string rendered
    local render = function(winid, maxwidth)
        local eval = vim.api.nvim_eval_statusline(vim.o.statusline, {
            winid    = winid or 0,
            maxwidth = maxwidth or 200,
        })
        return eval.str
    end

    --- Asserts that needle appears in haystack.
    ---@param haystack string
    ---@param needle   string
    ---@return nil
    local has = function(haystack, needle)
        eq(haystack:find(needle, 1, true) ~= nil, true)
    end

    --- Builds a repository fixture, registers it for teardown, and returns
    --- the current buffer showing its resolved file.
    ---@param opt? { remote?: boolean, subdir?: string, name?: string }
    ---@return integer bufnr
    local shown = function(opt)
        local dir, file = fixture(opt)
        dirs[#dirs + 1] = dir

        local bufnr = resolved(file)
        vim.api.nvim_set_current_buf(bufnr)
        return bufnr
    end

    it("splices over the default's filename item", function()
        has(vim.o.statusline, "util.statusline'.segment")
        has(vim.o.statusline, "util.statusline'.fallback")
        eq(vim.o.statusline:find("%<%f", 1, true), nil)
    end)

    it("preserves the rest of the default statusline", function()
        -- The default carries far more than `%f`; dropping any of it would
        -- be a silent regression
        for _, item in ipairs({
            "%h%w%m%r",
            "diagnostic.status",
            "rulerformat",
            "keymap_name",
            "busy",
            "progress_status",
        }) do
            has(vim.o.statusline, item)
        end
    end)

    it("is idempotent", function()
        -- `value` reads the option's default, never its live value, so
        -- applying it twice cannot splice into its own output
        local once = vim.o.statusline
        statusline.setup()
        eq(vim.o.statusline, once)
    end)

    it("renders the segment", function()
        shown()
        has(render(), "~example-owner/example-repo.git:stl-test:/file.lua")
    end)

    it("renders a % in a filename literally", function()
        -- The regression test for the `%{}` vs `%{%...%}` item form: the
        -- nested form re-parses its result, eating "%i" as an item and
        -- collapsing "%%", so this name would come back as "werd%.lua"
        shown({ remote = false, name = "we%ird%%.lua" })
        has(render(), "we%ird%%.lua")
    end)

    it("defers to %f in a quickfix window", function()
        -- The reason the fallback emits a literal `%f` instead of this
        -- module reproducing it: `nvim_buf_get_name` is "" here, so a
        -- hand-rolled fallback would render a blank filename
        vim.cmd("copen")
        has(render(), "[Quickfix List]")
        vim.cmd("cclose")
    end)

    it("defers to %f for a named special buffer", function()
        -- The other half of what `%f` does for free: shortening a path
        -- against the home directory. A real `:help` buffer would be the
        -- truer fixture, but `:help` prompts on stdin, which deadlocks a
        -- headless `-l` run, so the buffer type is faked instead.
        local dir, file = fixture()
        dirs[#dirs + 1] = dir

        local bufnr = vim.fn.bufadd(file)
        vim.fn.bufload(bufnr)
        vim.bo[bufnr].buftype = "help"
        vim.api.nvim_set_current_buf(bufnr)

        has(render(), "file.lua")
        eq(render():find("example-repo.git", 1, true), nil)
    end)

    it("defers to %f for a nameless buffer", function()
        vim.cmd("enew")
        has(render(), "[No Name]")
    end)

    it("reports each window's own repository", function()
        local one = shown({ subdir = "one" })
        vim.cmd("vsplit")
        local two = shown({ subdir = "two" })

        -- Pair each window with the buffer it actually holds, rather than
        -- assuming which way `vsplit` ordered them
        ---@type table<integer, string>
        local want = {
            [one] = "example-repo.git:stl-test:/one/file.lua",
            [two] = "example-repo.git:stl-test:/two/file.lua",
        }
        for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local expected = want[vim.api.nvim_win_get_buf(winid)]
            if expected then
                has(render(winid), expected)
            end
        end
        vim.cmd("only")
    end)

    it("truncates a long segment from the left", function()
        shown()

        -- The spliced items keep the default's leading `%<`, so a segment
        -- too wide for the window loses its head rather than its tail:
        -- the filename stays legible, the slug is what goes
        local rendered = render(0, 40)
        has(rendered, "file.lua")
        has(rendered, "<")
        eq(rendered:find("example-owner", 1, true), nil)
    end)
end)
