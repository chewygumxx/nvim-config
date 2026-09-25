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

--- Runs git in dir and returns its trimmed stdout.
---
--- A fixture command that fails is a broken test rather than a result to
--- assert on, so this raises instead of folding the failure into "": a
--- swallowed setup failure only resurfaces later, as a puzzling assertion
--- about something else entirely.
---@param dir string Repository to run in
---@param ... string git arguments
---@return string stdout
local git = function(dir, ...)
    local args = { ... }
    local cmd  = { "git", "-C", dir }
    vim.list_extend(cmd, args)

    local result = vim.system(cmd, { text = true }):wait()
    if result.code ~= 0 then
        error(
            string.format(
                "fixture `git %s` failed (%d): %s",
                table.concat(args, " "),
                result.code,
                result.stderr or ""
            )
        )
    end
    return ((result.stdout or ""):gsub("%s+$", ""))
end

--- The commit ref points at, "" when it does not exist.
---
--- The one query that deliberately tolerates a non-zero exit:
--- `rev-parse --verify --quiet` fails for a ref that was never created,
--- and "no snapshot was taken" is an answer these tests assert on rather
--- than a broken fixture.
---@param dir string Repository to run in
---@param ref string Ref to resolve
---@return string commit
local tip = function(dir, ref)
    local result = vim.system({
        "git",
        "-C",
        dir,
        "rev-parse",
        "--verify",
        "--quiet",
        ref,
    }, { text = true }):wait()
    return ((result.stdout or ""):gsub("%s+$", ""))
end

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
    -- `--initial-branch` pins the ref name: without it the fixture would
    -- inherit whatever `init.defaultBranch` happens to be configured to.
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
        vim.wait(10000, function()
            at = tip(dir, ref)
            return at ~= "" and at ~= before
        end, 20
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

    before_each(function()
        notify = quieten()
        dir    = vim.fn.tempname()
        vim.fn.mkdir(dir, "p")
        git(dir, "init", "--quiet", "--initial-branch=" .. branch)
        git(dir, "config", "user.email", "test@example.invalid")
        git(dir, "config", "user.name", "Test")

        file = dir .. "/tracked.lua"
        vim.fn.writefile({ "committed" }, file)
        git(dir, "add", "tracked.lua")
        git(dir, "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "i")

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

        -- A no-op cannot be detected by waiting for an absence, so the
        -- bounded wait only guards against a premature read; the commit
        -- count below is what actually proves nothing was written.
        wip.snapshot(buf)
        vim.wait(2000, function()
            return false
        end)
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

        wip.snapshot(scratch)
        vim.wait(2000, function()
            return false
        end)

        eq(vim.b[scratch].cgxx_wip_location, false)
        eq(tip(dir, ref), "")
        vim.api.nvim_buf_delete(scratch, { force = true })
    end)

    it("skips a file outside any repository", function()
        local outside = vim.fn.tempname()
        vim.fn.writefile({ "loose" }, outside)
        local loose = open(outside)

        wip.snapshot(loose)
        vim.wait(2000, function()
            return false
        end)

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
