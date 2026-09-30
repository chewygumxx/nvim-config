#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_biome.lua
--
--

--
-- `util.biome.enabled` is the whole of the rule both `lsp/biome.lua` and
-- the conform spec follow, so it is asserted here against directory trees
-- rather than through either caller. A bare `.git` directory is all
-- `vim.fs.root` needs to see a repository, so no git process is spawned.
--

local biome = require("util.biome")
---@type mini.test
local MiniTest = require("mini.test")
local eq       = MiniTest.expect.equality

--- Writes each file under `root`, creating directories on the way.
---@param root  string
---@param files table<string, string> repo-relative path to contents
---@return nil
local tree = function(root, files)
    for path, text in pairs(files) do
        local full = vim.fs.joinpath(root, path)
        vim.fn.mkdir(vim.fs.dirname(full), "p")
        vim.fn.writefile(vim.split(text, "\n"), full)
    end
end

describe("util.biome.enabled", function()
    ---@type string
    local root
    ---@type string
    local repo
    ---@type integer[]
    local bufs

    --- A buffer named for `path` inside the repository, never loaded.
    ---@param path string
    ---@return integer buf
    local buf_at = function(path)
        local buf = vim.fn.bufadd(vim.fs.joinpath(repo, path))
        table.insert(bufs, buf)
        return buf
    end

    before_each(function()
        root = vim.fn.tempname()
        repo = vim.fs.joinpath(root, "repo")
        vim.fn.mkdir(vim.fs.joinpath(repo, ".git"), "p")
        bufs = {}
    end)

    after_each(function()
        for _, buf in ipairs(bufs) do
            vim.api.nvim_buf_delete(buf, { force = true })
        end
        vim.fn.delete(root, "rf")
    end)

    it("falls back to Biome where nothing is configured", function()
        eq(biome.enabled(buf_at("src/index.ts")), true)
    end)

    it("stands aside for a prettier config", function()
        tree(repo, { [".prettierrc"] = "{}" })
        eq(biome.enabled(buf_at("src/index.ts")), false)
    end)

    it("stands aside for an eslint flat config", function()
        tree(repo, { ["eslint.config.js"] = "export default []" })
        eq(biome.enabled(buf_at("src/index.ts")), false)
    end)

    it("stands aside for a prettier key in package.json", function()
        tree(repo, { ["package.json"] = [[{ "prettier": {} }]] })
        eq(biome.enabled(buf_at("index.js")), false)
    end)

    it("stands aside for an eslintConfig key in package.json", function()
        tree(repo, { ["package.json"] = [[{ "eslintConfig": {} }]] })
        eq(biome.enabled(buf_at("index.js")), false)
    end)

    it("does not count a prettier dependency as configuration", function()
        tree(repo, {
            ["package.json"] = [[{ "devDependencies": { "prettier": "3" } }]],
        })
        eq(biome.enabled(buf_at("index.js")), true)
    end)

    it("prefers an explicit Biome config over eslint", function()
        tree(repo, { ["biome.json"] = "{}", [".eslintrc.json"] = "{}" })
        eq(biome.enabled(buf_at("index.js")), true)
    end)

    it("counts a @biomejs/biome dependency as choosing Biome", function()
        tree(repo, {
            [".prettierrc"]  = "{}",
            ["package.json"] = [[{ "devDependencies": { "@biomejs/biome": "2" } }]],
        })
        eq(biome.enabled(buf_at("index.js")), true)
    end)

    it("finds a config in an ancestor inside the repository", function()
        tree(repo, {
            [".prettierrc"]               = "{}",
            ["packages/app/package.json"] = "{}",
        })
        eq(biome.enabled(buf_at("packages/app/src/main.tsx")), false)
    end)

    it("ignores a config above the repository root", function()
        -- A stray config in a parent directory, eg. `$HOME`, does not
        -- speak for a repository that has none of its own
        tree(root, { [".prettierrc"] = "{}" })
        eq(biome.enabled(buf_at("index.js")), true)
    end)

    it("survives a malformed package.json", function()
        tree(repo, { ["package.json"] = "{ not json" })
        eq(biome.enabled(buf_at("index.js")), true)
    end)
end)
