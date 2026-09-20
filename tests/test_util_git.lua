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
local eq  = MiniTest.expect.equality

describe("util.git", function()
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

    after_each(function() vim.fn.delete(dir, "rf") end)

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
end)
