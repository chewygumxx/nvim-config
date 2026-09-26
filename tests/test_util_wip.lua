#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_wip.lua
--
--

local wip = require("util.wip")
local eq  = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

---@type cgxx.test.helpers
local helpers = dofile("tests/helpers.lua")
local git     = helpers.git
local tip     = helpers.tip

--- Replaces `vim.notify` with one that drops anything below ERROR, so
--- the module's progress messages stay out of MiniTest's own output
--- while a genuine snapshot failure still gets printed. Returns the
--- original, for the caller to restore.
---@return fun(msg: string, level?: integer, opts?: table) original
local quieten = function()
    local original = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(msg, level, opts)
        if level == vim.log.levels.ERROR then
            original(msg, level, opts)
        end
    end
    return original
end

describe("util.wip.snapshot", function()
    -- The fixture pins this branch, so the ref name under test is known
    -- rather than inherited from `init.defaultBranch`
    local branch = "wip-test"
    local ref    = "refs/wip/" .. branch

    ---@type string, string, integer
    local dir, file, buf

    ---@type fun(msg: string, level?: integer, opts?: table)
    local notify

    --- Reads back what ref stores for path, byte for byte. `text = true`
    --- is deliberately omitted: it rewrites "\r\n" to "\n", which would
    --- hide exactly the line-ending behaviour being asserted.
    ---@param path string Root-relative path
    ---@return string bytes
    local stored = function(path)
        local result = vim.system({
            "git",
            "-C",
            dir,
            "show",
            ref .. ":" .. path,
        }):wait()
        return result.stdout or ""
    end

    --- Waits for ref to move off before, returning its new tip.
    ---@param before string Tip to wait for a change from ("" if unborn)
    ---@return string tip
    local advanced = function(before)
        local at = before
        -- Asserted rather than waited out: every caller goes on to
        -- compare the returned tip, and a snapshot that never happened
        -- would otherwise be reported as whatever `before` was
        assert(
            vim.wait(10000, function()
                at = tip(dir, ref)
                return at ~= "" and at ~= before
            end, 20
            ),
            ref .. " never moved off " .. (before == "" and "unborn" or before)
        )
        return at
    end

    --- Opens path in a new current buffer and returns its number.
    ---@param path string
    ---@return integer bufnr
    local open = function(path)
        vim.cmd.edit(vim.fn.fnameescape(path))
        return vim.api.nvim_get_current_buf()
    end

    --- Runs act and returns the message it caused `vim.notify` to be given.
    ---
    --- This is the fence that the cases below used to approximate with
    --- `vim.wait(2000, function() return false end)`, ie. a sleep. An
    --- absence cannot be waited for, but `M.snapshot`'s `report` argument
    --- makes it announce whichever outcome it reached, the two that write
    --- nothing included, so "nothing happened" can be established by
    --- waiting for a positive answer rather than by guessing how long
    --- nothing takes. Three of those sleeps were 2000 ms each, against a
    --- whole suite that runs in twelve seconds.
    ---@param act fun(): nil
    ---@return string message
    local announced = function(act)
        ---@type string?
        local said  = nil
        local outer = vim.notify

        ---@param msg    string
        ---@param _level integer?
        ---@param _opts  table?
        ---@return nil
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function(msg, _level, _opts)
            said = msg
        end

        local ok, err = pcall(act)
        local arrived = vim.wait(10000, function()
            return said ~= nil
        end, 20
        )

        -- Restored before either assert, so a raising `act` cannot leave
        -- the capture installed for every case after this one
        vim.notify = outer
        assert(ok, err)
        assert(arrived and said, "no WIP notification arrived")
        return said
    end

    before_each(function()
        notify    = quieten()
        dir, file = helpers.repo({
            branch   = branch,
            remote   = false,
            name     = "tracked.lua",
            contents = { "committed" },
            commit   = "i",
        })

        buf = open(file)
    end)

    after_each(function()
        vim.notify = notify
        vim.api.nvim_buf_delete(buf, { force = true })
        vim.fn.delete(dir, "rf")
    end)

    it("records unsaved buffer text, leaving the file on disk", function()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            "committed",
            "unsaved",
        })
        wip.snapshot(buf)
        eq(advanced("") ~= "", true)

        eq(stored("tracked.lua"), "committed\nunsaved\n")
        eq(vim.fn.readfile(file), { "committed" })
        eq(vim.bo[buf].modified, true)
    end)

    it("leaves HEAD, the index and the working tree alone", function()
        local head = git(dir, "rev-parse", "HEAD")
        vim.fn.writefile({ "staged" }, dir .. "/staged.txt")
        git(dir, "add", "staged.txt")

        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "edited" })
        wip.snapshot(buf)
        eq(advanced("") ~= "", true)

        eq(git(dir, "rev-parse", "HEAD"), head)
        eq(git(dir, "status", "--short"), "A  staged.txt")
        eq(vim.fn.readfile(file), { "committed" })
        eq(vim.fn.glob(dir .. "/.git/cgxx-wip-index.*"), "")
    end)

    it("keeps the wip ref out of the branch namespace", function()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "edited" })
        wip.snapshot(buf)
        eq(advanced("") ~= "", true)

        eq(
            git(dir, "branch", "--list", "--format=%(refname)"),
            "refs/heads/" .. branch
        )
    end)

    it("does not commit when the text matches the ref tip", function()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "first" })
        wip.snapshot(buf)
        local first = advanced("")

        -- Taken with `report` on and waited for by its own answer: "no
        -- change since last snapshot" is the module saying it got as far
        -- as comparing trees and declined to commit, which is the claim
        -- this case makes. The commit count below still proves nothing was
        -- written.
        eq(
            announced(function()
                wip.snapshot(buf, true)
            end),
            "WIP: no change since last snapshot"
        )
        eq(tip(dir, ref), first)

        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "second" })
        wip.snapshot(buf)
        eq(advanced(first) ~= first, true)

        -- The fixture commit plus two snapshots, not three
        eq(git(dir, "rev-list", "--count", ref), "3")
    end)

    it("chains each snapshot onto the previous one", function()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "first" })
        wip.snapshot(buf)
        local first = advanced("")

        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "second" })
        wip.snapshot(buf)
        local second = advanced(first)

        eq(git(dir, "rev-parse", second .. "^"), first)
        eq(
            git(dir, "log", "-1", "--format=%s", second),
            ("wip(%s): tracked.lua"):format(branch)
        )
    end)

    it("honours 'fileformat' when serialising the buffer", function()
        vim.bo[buf].fileformat = "dos"
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "a", "b" })
        wip.snapshot(buf)
        eq(advanced("") ~= "", true)

        eq(stored("tracked.lua"), "a\r\nb\r\n")
    end)

    it("honours a buffer with no trailing newline", function()
        vim.bo[buf].endofline    = false
        vim.bo[buf].fixendofline = false
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "a", "b" })
        wip.snapshot(buf)
        eq(advanced("") ~= "", true)

        eq(stored("tracked.lua"), "a\nb")
    end)

    it("preserves the tracked file mode", function()
        local exe = dir .. "/hook.sh"
        vim.fn.writefile({ "#!/bin/sh" }, exe)
        vim.fn.setfperm(exe, "rwxr-xr-x")
        git(dir, "add", "hook.sh")
        git(dir, "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "h")

        local exebuf = open(exe)
        vim.api.nvim_buf_set_lines(exebuf, 0, -1, false, {
            "#!/bin/sh",
            "echo edited",
        })
        wip.snapshot(exebuf)
        eq(advanced("") ~= "", true)

        eq(git(dir, "ls-tree", ref, "hook.sh"):match("^%d+"), "100755")
        vim.api.nvim_buf_delete(exebuf, { force = true })
    end)

    it("skips a file git does not track", function()
        local untracked = dir .. "/untracked.txt"
        vim.fn.writefile({ "scratch" }, untracked)
        local scratch = open(untracked)

        -- Reported rather than slept through: ineligibility is decided
        -- before any async work starts, so the answer is already there
        eq(
            announced(function()
                wip.snapshot(scratch, true)
            end),
            "WIP: buffer is not a tracked file"
        )

        eq(vim.b[scratch].cgxx_wip_location, false)
        eq(tip(dir, ref), "")
        vim.api.nvim_buf_delete(scratch, { force = true })
    end)

    it("skips a file outside any repository", function()
        local outside = vim.fn.tempname()
        vim.fn.writefile({ "loose" }, outside)
        local loose = open(outside)

        eq(
            announced(function()
                wip.snapshot(loose, true)
            end),
            "WIP: buffer is not a tracked file"
        )

        eq(vim.b[loose].cgxx_wip_location, false)
        vim.api.nvim_buf_delete(loose, { force = true })
        vim.fn.delete(outside)
    end)

    it("drop deletes the branch's wip ref", function()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "edited" })
        wip.snapshot(buf)
        eq(advanced("") ~= "", true)

        -- Waiting on the notification rather than the ref: the ref is
        -- already gone by the time `vim.system` schedules its callback, so
        -- polling the ref can return while that callback is still pending,
        -- and it would then print after `vim.notify` had been restored.
        ---@type string?
        local dropped
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function(msg)
            dropped = msg
        end

        wip.drop()
        vim.wait(10000, function()
            return dropped ~= nil
        end, 20
        )

        eq(dropped, "WIP: deleted " .. ref)
        eq(tip(dir, ref), "")
    end)
end)

describe("util.wip.enable/disable/toggle", function()
    ---@type integer
    local buf

    ---@type fun(msg: string, level?: integer, opts?: table)
    local notify

    before_each(function()
        notify = quieten()
        buf    = vim.api.nvim_create_buf(false, true)
    end)
    after_each(function()
        vim.notify = notify
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("enable sets the buffer-local flag", function()
        wip.enable(buf)
        eq(vim.b[buf].cgxx_wip, true)
    end)

    it("disable clears the buffer-local flag", function()
        wip.enable(buf)
        wip.disable(buf)
        eq(vim.b[buf].cgxx_wip, false)
    end)

    it("toggle treats an unset flag as enabled", function()
        eq(vim.b[buf].cgxx_wip, nil)
        wip.toggle(buf)
        eq(vim.b[buf].cgxx_wip, false)
        wip.toggle(buf)
        eq(vim.b[buf].cgxx_wip, true)
    end)
end)

describe("util.wip.command", function()
    ---@type integer
    local buf

    --- Invokes `M.command` with buf current, returning the messages it
    --- pushed through `vim.notify`. Only the argument fields `M.command`
    --- actually reads are supplied, hence the cast.
    ---@param fargs string[] Command arguments
    ---@param bang  boolean  Whether the command was called with "!"
    ---@return string[] notified
    local invoke = function(fargs, bang)
        ---@type string[]
        local notified = {}
        local notify   = vim.notify
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function(msg)
            table.insert(notified, msg)
        end

        ---@type vim.api.keyset.create_user_command.command_args
        ---@diagnostic disable-next-line: missing-fields
        local args = { fargs = fargs, bang = bang }

        local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
            wip.command(args)
        end)

        vim.notify = notify
        assert(ok, err)
        return notified
    end

    before_each(function()
        buf = vim.api.nvim_create_buf(false, true)
    end)
    after_each(function()
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("completes every known action, sorted", function()
        eq(wip.complete(), {
            "disable",
            "drop",
            "enable",
            "snapshot",
            "toggle",
        })
    end)

    it("defaults to toggle with no argument", function()
        invoke({}, false)
        eq(vim.b[buf].cgxx_wip, false)
    end)

    it("dispatches a named action", function()
        invoke({ "enable" }, false)
        eq(vim.b[buf].cgxx_wip, true)
    end)

    it("warns on an unknown action", function()
        local notified = invoke({ "bogus" }, false)
        eq(#notified, 1)
        eq(notified[1]:match("unknown action bogus") ~= nil, true)
    end)

    it("refuses drop without a bang", function()
        -- A scratch buffer is not a tracked file, so `M.drop` would warn
        -- about that instead; asserting on the bang warning is what shows
        -- the bangless call never reached `M.drop` at all.
        local notified = invoke({ "drop" }, false)
        eq(#notified, 1)
        eq(notified[1]:match("XXWip! drop") ~= nil, true)
    end)

    it("reaches drop with a bang", function()
        local notified = invoke({ "drop" }, true)
        eq(#notified, 1)
        eq(notified[1]:match("not a tracked file") ~= nil, true)
    end)
end)

describe("util.wip.autocmd", function()
    -- The wiring `test_autocmd.lua` can only assert the existence of: that
    -- file proves the "cgxx.wip" augroup is non-empty, not that a keystroke
    -- leads to a snapshot. Everything below drives the real events.
    local branch = "wip-acmd-test"
    local ref    = "refs/wip/" .. branch

    ---@type string, string, integer
    local dir, file, buf

    ---@type fun(msg: string, level?: integer, opts?: table)
    local notify

    ---@type integer
    local debounce

    before_each(function()
        notify    = quieten()
        dir, file = helpers.repo({
            branch   = branch,
            remote   = false,
            name     = "tracked.lua",
            contents = { "committed" },
            commit   = "i",
        })

        -- Shortened from 2000 ms, which is a sensible interval for a human
        -- typing and an absurd one for a test to sit through. The interval
        -- is a module field precisely so it can be reached; nothing else
        -- had ever done so, which is why the debounced path was untested
        debounce     = wip.debounce
        wip.debounce = 20

        vim.cmd.edit(vim.fn.fnameescape(file))
        buf = vim.api.nvim_get_current_buf()
        wip.autocmd()
    end)

    after_each(function()
        -- Cleared rather than deleted, for the reason `test_autocmd.lua`
        -- gives: emptying the group is what stops these autocmds firing
        -- during every later test file
        vim.api.nvim_create_augroup("cgxx.wip", { clear = true })
        wip.debounce = debounce
        vim.notify   = notify
        vim.api.nvim_buf_delete(buf, { force = true })
        vim.fn.delete(dir, "rf")
    end)

    --- Waits for ref to come into existence, returning its tip.
    ---@return string tip
    local snapshotted = function()
        ---@type string
        local at = ""
        assert(
            vim.wait(10000, function()
                at = helpers.tip(dir, ref)
                return at ~= ""
            end, 20
            ),
            ref .. " was never written"
        )
        return at
    end

    --- The number of commits reachable from ref, fixture commit included.
    ---@return string count
    local commits = function()
        return helpers.git(dir, "rev-list", "--count", ref)
    end

    it("snapshots a change once the typing stops", function()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "typed" })
        vim.api.nvim_exec_autocmds("TextChanged", { buffer = buf })

        eq(snapshotted() ~= "", true)
        eq(commits(), "2")
    end)

    it("coalesces a burst of changes into one snapshot", function()
        -- The whole point of the debounce: each event rearms the timer, so
        -- a burst costs one snapshot rather than one per keystroke
        for i = 1, 5 do
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "typed " .. i })
            vim.api.nvim_exec_autocmds("TextChangedI", { buffer = buf })
        end

        eq(snapshotted() ~= "", true)
        eq(commits(), "2")
    end)

    it("snapshots immediately when the buffer is written", function()
        -- Not through `nvim_exec_autocmds`: a real `:write` is what a
        -- session does, and it fires `BufWritePost` itself
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "saved" })
        vim.api.nvim_buf_call(buf, function()
            vim.cmd("silent write")
        end)

        eq(snapshotted() ~= "", true)
    end)

    it("snapshots when focus is lost", function()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "unfocused" })
        vim.api.nvim_exec_autocmds("FocusLost", { buffer = buf })

        eq(snapshotted() ~= "", true)
    end)

    it("leaves a disabled buffer alone", function()
        -- Proven by a fence rather than by waiting out an absence: the
        -- second event is eligible and must produce a snapshot, and the
        -- commit count then says the first produced none. `FocusLost` is
        -- used for both because it snapshots synchronously, so the two
        -- cannot be coalesced by the debounce the way `TextChanged` would
        vim.b[buf].cgxx_wip = false
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "ignored" })
        vim.api.nvim_exec_autocmds("FocusLost", { buffer = buf })

        vim.b[buf].cgxx_wip = true
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "recorded" })
        vim.api.nvim_exec_autocmds("FocusLost", { buffer = buf })

        eq(snapshotted() ~= "", true)
        eq(commits(), "2")
    end)

    it("starts snapshotting a newly tracked file", function()
        -- `cgxx_wip_location` is cached per buffer, ineligible answers
        -- included, so a file that was untracked when it was first opened
        -- would stay ineligible for the life of the buffer. Clearing that
        -- cache on `BufWritePost` is what lets `git add` take effect
        local fresh = dir .. "/fresh.lua"
        vim.fn.writefile({ "new" }, fresh)
        vim.cmd.edit(vim.fn.fnameescape(fresh))
        local newbuf = vim.api.nvim_get_current_buf()

        wip.snapshot(newbuf)
        eq(vim.b[newbuf].cgxx_wip_location, false)

        helpers.git(dir, "add", "fresh.lua")
        vim.api.nvim_exec_autocmds("BufWritePost", { buffer = newbuf })

        eq(snapshotted() ~= "", true)
        eq(vim.b[newbuf].cgxx_wip_location ~= false, true)
        vim.api.nvim_buf_delete(newbuf, { force = true })
    end)
end)
