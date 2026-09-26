#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/helpers.lua
--
--

--
-- Fixtures shared by the test files that shell out to git.
--
-- Loaded with `dofile("tests/helpers.lua")` rather than `require`: nothing
-- puts `tests/` on the Lua module path, and it must not be, since
-- `collect.find_files` globs `tests/**/test_*.lua` and a module named like
-- a test file would be collected as one. The filename deliberately does
-- not match that glob.
--
-- Four files (`test_util_git`, `test_util_wip`, `test_util_header`,
-- `test_util_statusline`) each held their own copy of `git` below, three
-- of them character for character identical, plus their own variation on
-- `repo`. The knowledge was copied along with the code, which is the good
-- case; the bad case is the next lesson landing in only one copy.
--

---@class cgxx.test.helpers
local M = {}

--- `MiniTest.expect.equality` with a label attached.
---
--- `expect.equality` takes no message, so every case that asserts the same
--- thing about many items has to smuggle the item's name into the
--- comparison, ie. `eq({ name, got }, { name, want })`. It reads oddly, it
--- doubles every literal, and a failure describes a two-element table
--- rather than the thing that was wrong.
---
--- `MiniTest.new_expectation` is what the framework offers instead: the
--- predicate decides, and `fail_context` writes the message. Existing
--- padded call sites are not wrong, and are worth migrating when they are
--- next touched rather than in a sweep of their own.
---@type fun(label: string, left: any, right: any)
M.labelled_equality = require("mini.test") --[[@as mini.test]]
    .new_expectation(
        "labelled equality",
        ---@param _label string
        ---@param left   any
        ---@param right  any
        ---@return boolean equal
        function(_label, left, right)
            return vim.deep_equal(left, right)
        end,
        ---@param label string
        ---@param left  any
        ---@param right any
        ---@return string context
        function(label, left, right)
            return string.format(
                "%s\nLeft:  %s\nRight: %s",
                label,
                vim.inspect(left),
                vim.inspect(right)
            )
        end
    )

--- Runs git in dir and returns its trimmed stdout.
---
--- A fixture command that fails is a broken test rather than a result to
--- assert on, so this raises instead of folding the failure into "". A
--- swallowed setup failure does not stay quiet, it resurfaces later as a
--- puzzling assertion about something else entirely: a `git commit` with
--- no identity configured is what once left `checkout --detach` with
--- nothing to detach from, failing three cases in CI only.
---@param dir string Repository to run in
---@param ... string git arguments
---@return string stdout
M.git = function(dir, ...)
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
--- and "no snapshot was taken" is an answer tests assert on rather than a
--- broken fixture.
---@param dir string Repository to run in
---@param ref string Ref to resolve
---@return string commit
M.tip = function(dir, ref)
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

---@class (exact) cgxx.test.helpers.repo.opts
---@field branch   string    Initial branch name, required rather than defaulted
---@field remote   boolean?  Add an "origin" remote. Default: true
---@field subdir   string?   Root-relative directory to put the file in
---@field name     string?   File name. Default: "file.lua"
---@field contents string[]? File lines. Default: { "" }
---@field commit   string?   Commit the file under this message

--- The "origin" URL every fixture repository carries, in the SSH form
--- `util.git`'s slug parsing has to cope with.
M.remote = "git@github.com:example-owner/example-repo.git"

--- Builds a repository fixture under `tempname()` holding one file.
---
--- `branch` has no default on purpose. Pinning it is what keeps a fixture
--- from inheriting whatever `init.defaultBranch` is configured to on the
--- machine running the suite, and giving each file its own name is what
--- makes an assertion about a ref name say which fixture it came from.
---@param opt cgxx.test.helpers.repo.opts
---@return string dir, string file
M.repo = function(opt)
    assert(opt.branch, "a repository fixture must pin its initial branch")

    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    M.git(dir, "init", "--quiet", "--initial-branch=" .. opt.branch)

    -- An identity has to be set per repository rather than inherited: a CI
    -- runner has no global `user.name`/`user.email`, and without one
    -- `git commit` fails outright, so a fixture that goes on to detach
    -- HEAD would silently stay on its branch instead
    M.git(dir, "config", "user.email", "test@example.invalid")
    M.git(dir, "config", "user.name", "Test")

    if opt.remote ~= false then
        M.git(dir, "remote", "add", "origin", M.remote)
    end

    local parent = opt.subdir and (dir .. "/" .. opt.subdir) or dir
    vim.fn.mkdir(parent, "p")

    local name = opt.name or "file.lua"
    local file = parent .. "/" .. name
    vim.fn.writefile(opt.contents or { "" }, file)

    if opt.commit then
        local path = opt.subdir and (opt.subdir .. "/" .. name) or name
        M.git(dir, "add", path)
        -- Signing forced off rather than left to the machine: a gpg
        -- passphrase prompt has nowhere to go from here and would hang
        M.git(
            dir,
            "-c",
            "commit.gpgsign=false",
            "commit",
            "--quiet",
            "-m",
            opt.commit
        )
    end

    return dir, file
end

return M
