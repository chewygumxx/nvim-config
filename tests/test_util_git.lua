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

describe("util.git", function()
    ---@type string, string
    local dir, file

    before_each(function()
        dir = vim.fn.tempname()
        vim.fn.mkdir(dir, "p")
        vim.system({ "git", "-C", dir, "init", "--quiet" }):wait()
        vim.system({
            "git",
            "-C",
            dir,
            "remote",
            "add",
            "origin",
            "git@github.com:example-owner/example-repo.git",
        }):wait()
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
        vim.system({
            "git",
            "-C",
            dir,
            "remote",
            "set-url",
            "origin",
            "https://github.com/example-owner/example-repo.git",
        }):wait()
        eq(git.slug(file), "example-owner/example-repo")
    end)

    it("returns nil when there is no origin remote", function()
        vim.system({ "git", "-C", dir, "remote", "remove", "origin" }):wait()
        eq(git.slug(file), nil)
    end)

    it("resolves the owner/repo slug from a named remote", function()
        vim.system({
            "git",
            "-C",
            dir,
            "remote",
            "add",
            "upstream",
            "git@github.com:upstream-owner/upstream-repo.git",
        }):wait()
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
        -- The fixture's `git init` inherits whatever `init.defaultBranch`
        -- is configured to, so rename to a known value rather than
        -- asserting against an ambient one
        vim.system({ "git", "-C", dir, "branch", "-M", "git-test" }):wait()
        eq(git.branch(file), "git-test")
    end)

    it("returns nil for a detached HEAD", function()
        vim.fn.writefile({ "" }, file)
        vim.system({ "git", "-C", dir, "add", "-A" }):wait()
        vim.system({
            "git",
            "-C",
            dir,
            "-c",
            "commit.gpgsign=false",
            "commit",
            "--quiet",
            "-m",
            "init",
        }):wait()
        vim.system({
            "git",
            "-C",
            dir,
            "checkout",
            "--quiet",
            "--detach",
            "HEAD",
        }):wait()
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

    --- Runs git in dir and returns its trimmed stdout, "" on failure.
    ---@param ... string git arguments
    ---@return string stdout
    local run = function(...)
        local cmd = { "git", "-C", dir }
        vim.list_extend(cmd, { ... })
        local result = vim.system(cmd, { text = true }):wait()
        if result.code ~= 0 or not result.stdout then
            return ""
        end
        return (result.stdout:gsub("%s+$", ""))
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
        vim.wait(10000, settled, 20)
        return got, fast
    end

    before_each(function()
        dir = vim.fn.tempname()
        vim.fn.mkdir(dir, "p")
        -- `--initial-branch` pins the ref name: without it the fixture
        -- would inherit whatever `init.defaultBranch` is configured to
        run("init", "--quiet", "--initial-branch=info-test")
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
