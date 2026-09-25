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

--- Runs git in dir and returns its trimmed stdout, "" on failure.
---@param dir string Repository to run in
---@param ... string git arguments
---@return string stdout
local git = function(dir, ...)
    local cmd = { "git", "-C", dir }
    vim.list_extend(cmd, { ... })
    local result = vim.system(cmd, { text = true }):wait()
    if result.code ~= 0 or not result.stdout then
        return ""
    end
    return (result.stdout:gsub("%s+$", ""))
end

--- Builds a repository fixture holding one file.
---@param opt? { remote?: boolean, subdir?: string, name?: string }
---@return string dir, string file
local fixture = function(opt)
    opt       = opt or {}
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    git(dir, "init", "--quiet", "--initial-branch=stl-test")
    -- An identity has to be set per fixture rather than inherited: a CI
    -- runner has no global `user.name`/`user.email`, and without one
    -- `git commit` fails outright, so a fixture that goes on to detach
    -- HEAD would silently stay on its branch instead
    git(dir, "config", "user.email", "test@example.invalid")
    git(dir, "config", "user.name", "Test")
    if opt.remote ~= false then
        git(
            dir,
            "remote",
            "add",
            "origin",
            "git@github.com:example-owner/example-repo.git"
        )
    end

    local parent = opt.subdir and (dir .. "/" .. opt.subdir) or dir
    vim.fn.mkdir(parent, "p")
    local file = parent .. "/" .. (opt.name or "file.lua")
    vim.fn.writefile({ "" }, file)
    return dir, file
end

--- Blocks until bufnr's segment has been resolved and cached.
---@param bufnr integer
---@return nil
local await = function(bufnr)
    local settled = function()
        return vim.b[bufnr].cgxx_statusline ~= nil
    end
    vim.wait(10000, settled, 20)
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

    it("discards an answer for a name the buffer no longer has", function()
        local _, file = track(fixture())
        local bufnr   = vim.fn.bufadd(file)
        vim.fn.bufload(bufnr)

        -- Start a resolve for the original name, then rename before it can
        -- land. The in-flight answer describes a file this buffer is no
        -- longer showing, so it must be dropped rather than cached.
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
