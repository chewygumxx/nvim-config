#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_nex_commit.lua
--
--

---@type cgxx.test.helpers
local helpers = dofile("tests/helpers.lua")
local nex     = require("util.nex")
---@type mini.test
local MiniTest = require("mini.test")
local eq       = MiniTest.expect.equality

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

--- Replaces `vim.notify` with one that drops anything below ERROR, so
--- the module's progress messages stay out of MiniTest's own output
--- while a genuine commit failure still gets printed. Returns the
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

describe("util.nex.commit", function()
    ---@type string, string, string
    local root, dir, path

    ---@type fun(msg: string, level?: integer, opts?: table)
    local notify

    --- Waits for the repository's commit count to reach want.
    ---@param want integer
    ---@return integer count
    local commits = function(want)
        local count = 0
        vim.wait(10000, function()
            count = tonumber(git(root, "rev-list", "--count", "HEAD")) or 0
            return count >= want
        end, 25
        )
        return count
    end

    before_each(function()
        notify = quieten()
        root   = vim.fn.tempname() .. "/nex"
        dir    = root .. "/note"
        vim.fn.mkdir(dir, "p")

        -- `--initial-branch` and an explicit identity keep the fixture
        -- off whatever this machine's git defaults happen to be
        vim.system({
            "git",
            "-C",
            root,
            "init",
            "--quiet",
            "--initial-branch=main",
        }):wait()
        git(root, "config", "user.name", "Nex Test")
        git(root, "config", "user.email", "nex@example.invalid")

        nex.root = root
        path     = dir .. "/2026-09-26-a-note.note.md"
        vim.fn.writefile({ "# A Note", "" }, path)
    end)

    after_each(function()
        vim.notify = notify
        nex.root   = vim.fn.expand("~/dev/nex")
        vim.fn.delete(vim.fn.fnamemodify(root, ":h"), "rf")
    end)

    it("recognises a note by its location and extension", function()
        eq(nex.is_note(path), true)
        eq(nex.is_note(root .. "/README.md"), false)
        eq(nex.is_note(dir .. "/notes.md"), false)
        eq(nex.is_note("/elsewhere/note/a.note.md"), false)
        eq(nex.is_note(""), false)
        eq(nex.is_note(nil), false)
    end)

    it("commits a brand new note onto an unborn HEAD", function()
        nex.commit(path)
        eq(commits(1), 1)
        eq(
            git(root, "log", "-1", "--format=%s"),
            "Add note/2026-09-26-a-note.note.md"
        )
    end)

    it("stages the note as part of committing it", function()
        nex.commit(path)
        eq(commits(1), 1)
        eq(git(root, "status", "--short"), "")
    end)

    it("says Update once the note is already in HEAD", function()
        nex.commit(path)
        eq(commits(1), 1)

        vim.fn.writefile({ "# A Note", "", "More." }, path)
        nex.commit(path)
        eq(commits(2), 2)
        eq(
            git(root, "log", "-1", "--format=%s"),
            "Update note/2026-09-26-a-note.note.md"
        )
    end)

    it("records the written content, not the staged index", function()
        nex.commit(path)
        eq(commits(1), 1)
        eq(
            git(root, "show", "HEAD:note/2026-09-26-a-note.note.md"),
            "# A Note"
        )
    end)

    it("makes no commit when the write changed nothing", function()
        nex.commit(path)
        eq(commits(1), 1)

        -- Announced rather than slept through: `report` makes the no-op
        -- say so, which is the fence `.claude/rules/tests.md` asks for
        eq(
            helpers.announced(function()
                nex.commit(path, true)
            end),
            "Nex: no change since last commit"
        )
        eq(tonumber(git(root, "rev-list", "--count", "HEAD")), 1)
    end)

    it("leaves unrelated staged work staged and uncommitted", function()
        nex.commit(path)
        eq(commits(1), 1)

        local other = root .. "/other.txt"
        vim.fn.writefile({ "unrelated" }, other)
        git(root, "add", "--", "other.txt")

        vim.fn.writefile({ "# A Note", "", "More." }, path)
        nex.commit(path)
        eq(commits(2), 2)

        eq(git(root, "status", "--short"), "A  other.txt")
        eq(
            git(root, "show", "--name-only", "--format=", "HEAD"),
            "note/2026-09-26-a-note.note.md"
        )
    end)

    it("ignores a path outside the note directory", function()
        local outside = root .. "/README.md"
        vim.fn.writefile({ "# Readme" }, outside)
        -- Refused before any async work starts, so the answer is there
        -- at once and there is nothing to wait for
        eq(
            helpers.announced(function()
                nex.commit(outside, true)
            end),
            "Nex: buffer is not a note under " .. root
        )
        eq(git(root, "rev-list", "--count", "HEAD"), "")
    end)

    describe("through its autocmd", function()
        ---@type integer
        local buf

        before_each(function()
            nex.autocmd()
            vim.cmd.edit(vim.fn.fnameescape(path))
            buf = vim.api.nvim_get_current_buf()
        end)

        after_each(function()
            -- Cleared rather than deleted, as the wip tests do, so the
            -- autocmd stops firing during every later test file
            vim.api.nvim_create_augroup("cgxx.nex", { clear = true })
            vim.api.nvim_buf_delete(buf, { force = true })
        end)

        --- Replaces the note's text and writes it the way a session does.
        ---@param lines string[]
        ---@return nil
        local write = function(lines)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.api.nvim_buf_call(buf, function()
                vim.cmd("silent write")
            end)
        end

        it("commits a note when it is written", function()
            write({ "# A Note", "", "Written." })
            eq(commits(1), 1)
        end)

        it("leaves a note alone while commit-on-write is off", function()
            -- Counted at the call rather than in the repository: the
            -- commit reads the file when it runs, so a later write's text
            -- would land in it either way. Whether to call is decided
            -- synchronously in the autocmd, so the count is final at once.
            nex.disable(buf)

            local calls = 0
            local real  = nex.commit
            ---@diagnostic disable-next-line: duplicate-set-field
            nex.commit    = function(note, report)
                calls = calls + 1
                return real(note, report)
            end
            local ok, err = pcall(write, { "# A Note", "", "Ignored." })
            nex.commit    = real
            assert(ok, err)

            eq(calls, 0)
        end)
    end)
end)

describe("util.nex commit-on-write toggles", function()
    ---@type integer
    local buf

    ---@type fun(msg: string, level?: integer, opts?: table)
    local notify

    before_each(function()
        notify = quieten()
        buf    = vim.api.nvim_create_buf(false, true)
    end)

    after_each(function()
        vim.notify            = notify
        vim.g.cgxx_nex_commit = nil
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("defaults to enabled, with no buffer variable set", function()
        eq(vim.b[buf].cgxx_nex_commit, nil)
    end)

    it("toggles the buffer variable off and back on", function()
        nex.toggle(buf)
        eq(vim.b[buf].cgxx_nex_commit, false)
        nex.toggle(buf)
        eq(vim.b[buf].cgxx_nex_commit, true)
    end)

    it("sets the buffer variable explicitly either way", function()
        nex.disable(buf)
        eq(vim.b[buf].cgxx_nex_commit, false)
        nex.enable(buf)
        eq(vim.b[buf].cgxx_nex_commit, true)
    end)

    --- Runs `XXNexNote` with fargs, from buf.
    ---@param fargs string[]
    ---@return nil
    local command = function(fargs)
        ---@type vim.api.keyset.create_user_command.command_args
        ---@diagnostic disable-next-line: missing-fields
        local args = { fargs = fargs }
        vim.api.nvim_buf_call(buf, function()
            nex.command(args)
        end)
    end

    it("dispatches a named action to the current buffer", function()
        command({ "disable" })
        eq(vim.b[buf].cgxx_nex_commit, false)
        command({ "toggle" })
        eq(vim.b[buf].cgxx_nex_commit, true)
    end)

    it("defaults to a new note with no argument", function()
        local calls = 0
        local real  = nex.new_note
        ---@diagnostic disable-next-line: duplicate-set-field
        nex.new_note  = function()
            calls = calls + 1
        end
        local ok, err = pcall(command, {})
        nex.new_note  = real
        assert(ok, err)

        eq(calls, 1)
    end)

    it("reports an unknown action rather than raising", function()
        eq(
            helpers.announced(function()
                command({ "bogus" })
            end),
            "XXNexNote: unknown action bogus"
        )
    end)

    it("offers every action as a completion", function()
        eq(nex.complete(), {
            "commit",
            "disable",
            "enable",
            "new",
            "toggle",
        })
    end)
end)
