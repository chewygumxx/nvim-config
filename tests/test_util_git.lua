#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_git.lua
--
--

local git = require("util.git")
local eq  = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

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
local git_in = function(dir, ...)
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

describe("util.git", function()
    ---@type string, string
    local dir, file

    before_each(function()
        dir = vim.fn.tempname()
        vim.fn.mkdir(dir, "p")
        -- `--initial-branch` pins the ref name: without it the fixture
        -- would inherit whatever `init.defaultBranch` is configured to
        git_in(dir, "init", "--quiet", "--initial-branch=git-test")
        -- An identity has to be set per fixture rather than inherited:
        -- a CI runner has no global `user.name`/`user.email`, and without
        -- one `git commit` fails outright, leaving later setup steps
        -- (`checkout --detach`) with nothing to act on
        git_in(dir, "config", "user.email", "test@example.invalid")
        git_in(dir, "config", "user.name", "Test")
        git_in(
            dir,
            "remote",
            "add",
            "origin",
            "git@github.com:example-owner/example-repo.git"
        )
        file = dir .. "/file.lua"
        vim.fn.writefile({ "" }, file)
    end)

    after_each(function()
        vim.fn.delete(dir, "rf")
    end)

    it("resolves the owner/repo slug from the origin remote", function()
        eq(git.slug(file), "example-owner/example-repo")
    end)

    it("strips a trailing .git suffix from the remote URL", function()
        git_in(
            dir,
            "remote",
            "set-url",
            "origin",
            "https://github.com/example-owner/example-repo.git"
        )
        eq(git.slug(file), "example-owner/example-repo")
    end)

    it("returns nil when there is no origin remote", function()
        git_in(dir, "remote", "remove", "origin")
        eq(git.slug(file), nil)
    end)

    it("resolves the owner/repo slug from a named remote", function()
        git_in(
            dir,
            "remote",
            "add",
            "upstream",
            "git@github.com:upstream-owner/upstream-repo.git"
        )
        eq(git.slug(file, "upstream"), "upstream-owner/upstream-repo")
    end)

    it("returns nil when the named remote does not exist", function()
        eq(git.slug(file, "upstream"), nil)
    end)

    it(
        "resolves a root-relative, colon-prefixed path inside the repo",
        function()
            local path = git.path(file)
            eq(path:sub(1, 1), ":")
            eq(path:match("/file%.lua$") ~= nil, true)
        end
    )

    it(
        "falls back to a home-relative path outside any git repository",
        function()
            local outside = vim.fn.tempname()
            vim.fn.writefile({ "" }, outside)
            eq(git.path(outside), vim.fn.fnamemodify(outside, ":~"))
            vim.fn.delete(outside)
        end
    )

    it("resolves the checked out branch", function()
        -- Pinned by the fixture's `--initial-branch`, never the machine's
        -- `init.defaultBranch`
        eq(git.branch(file), "git-test")
    end)

    it("follows a branch rename", function()
        git_in(dir, "branch", "-M", "renamed")
        eq(git.branch(file), "renamed")
    end)

    it("returns nil for a detached HEAD", function()
        vim.fn.writefile({ "" }, file)
        git_in(dir, "add", "-A")
        git_in(
            dir,
            "-c",
            "commit.gpgsign=false",
            "commit",
            "--quiet",
            "-m",
            "init"
        )
        git_in(dir, "checkout", "--quiet", "--detach", "HEAD")
        eq(git.branch(file), nil)
    end)

    it("returns nil outside any git repository", function()
        local outside = vim.fn.tempname()
        vim.fn.writefile({ "" }, outside)
        eq(git.branch(outside), nil)
        vim.fn.delete(outside)
    end)
end)

describe("util.git.info", function()
    ---@type string, string
    local dir, file

    --- Runs git in this describe's fixture, raising if it fails.
    ---@param ... string git arguments
    ---@return string stdout
    local run = function(...)
        return git_in(dir, ...)
    end

    --- Calls `M.info` and blocks until its callback has run.
    ---@param target string File to resolve from
    ---@return cgxx.git.info? info
    ---@return boolean fast        Whether the callback ran in a fast event
    local info_of = function(target)
        ---@type cgxx.git.info?
        local got
        local called, fast = false, true

        git.info(target, function(result)
            got = result
            -- `== true` keeps this a boolean: `vim.in_fast_event` is
            -- declared as returning nothing usable to assign directly
            fast   = vim.in_fast_event() == true
            called = true
        end)

        local settled = function()
            return called
        end
        -- Asserted, not merely waited on: `got` is `nil` both when the
        -- callback reported "no repository" and when it never ran at
        -- all, so without this the cases expecting nil would pass just
        -- as happily against an `M.info` that dropped its callback
        assert(
            vim.wait(10000, settled, 20),
            "util.git.info never called back for " .. target
        )
        return got, fast
    end

    before_each(function()
        dir = vim.fn.tempname()
        vim.fn.mkdir(dir, "p")
        -- `--initial-branch` pins the ref name: without it the fixture
        -- would inherit whatever `init.defaultBranch` is configured to
        run("init", "--quiet", "--initial-branch=info-test")
        -- An identity has to be set per fixture rather than inherited: a
        -- CI runner has no global one, and `git commit` fails without it
        run("config", "user.email", "test@example.invalid")
        run("config", "user.name", "Test")
        run(
            "remote",
            "add",
            "origin",
            "git@github.com:example-owner/example-repo.git"
        )
        file = dir .. "/file.lua"
        vim.fn.writefile({ "" }, file)
    end)

    after_each(function()
        vim.fn.delete(dir, "rf")
    end)

    it("reports prefix, branch and slug in one call", function()
        -- `assert` rather than an equality check on nil: it both fails the
        -- case and narrows the optional away for the field accesses below
        local info = assert(info_of(file))
        eq(info.prefix, "")
        eq(info.branch, "info-test")
        eq(info.slug, "example-owner/example-repo")
    end)

    it("reports the directory prefix of a nested file", function()
        vim.fn.mkdir(dir .. "/sub/deep", "p")
        local nested = dir .. "/sub/deep/file.lua"
        vim.fn.writefile({ "" }, nested)

        eq(assert(info_of(nested)).prefix, "sub/deep/")
    end)

    it("agrees with the synchronous branch helper", function()
        -- The whole justification for having both spellings is that they
        -- answer identically; this is what pins the shell to the Lua
        eq(assert(info_of(file)).branch, git.branch(file))
    end)

    it("reports an empty branch for a detached HEAD", function()
        run("add", "-A")
        run("-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "init")
        run("checkout", "--quiet", "--detach", "HEAD")

        eq(assert(info_of(file)).branch, "")
        eq(git.branch(file), nil)
    end)

    it("reports a nil slug without an origin remote", function()
        run("remote", "remove", "origin")

        local info = assert(info_of(file))
        eq(info.slug, nil)
        eq(info.branch, "info-test")
    end)

    it("reports nil outside any git repository", function()
        local outside = vim.fn.tempname()
        vim.fn.mkdir(outside, "p")
        local stray = outside .. "/file.lua"
        vim.fn.writefile({ "" }, stray)

        eq(info_of(stray), nil)
        vim.fn.delete(outside, "rf")
    end)

    it("reports nil for a directory that does not exist", function()
        eq(info_of(dir .. "/no/such/dir/file.lua"), nil)
    end)

    it("calls back outside a fast event", function()
        -- Callers are entitled to touch buffers and options, which a fast
        -- event forbids
        local _, fast = info_of(file)
        eq(fast, false)
    end)
end)
