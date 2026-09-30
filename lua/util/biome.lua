#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/biome.lua
--
--

--
-- Decides whether Biome or the eslint/prettier pair owns a buffer.
-- `lsp/biome.lua`, `lsp/eslint.lua` and `lua/spec/conform.nvim.lua` all
-- ask, and separate copies of the answer would let the language servers
-- and the formatter disagree about one file.
--
-- Biome wins when the repository configures it, stands aside when the
-- repository configures eslint or prettier instead, and is the fallback
-- when it configures none of them.
--

local M = {}

---@class util.biome.Tool
---@field files        string[] config filenames that name the tool
---@field package_keys string[] `package.json` keys that name the tool
---@field dependencies string[] packages whose presence names the tool

--- Biome's own evidence.
---@type util.biome.Tool
M.biome = {
    files        = {
        "biome.json",
        "biome.jsonc",
        ".biome.json",
        ".biome.jsonc",
    },
    package_keys = {},
    dependencies = { "@biomejs/biome" },
}

--- An eslint configuration, flat or legacy. `lsp/eslint.lua` starts the
--- server by this and nothing else.
---@type util.biome.Tool
M.eslint = {
    files        = {
        "eslint.config.js",
        "eslint.config.mjs",
        "eslint.config.cjs",
        "eslint.config.ts",
        "eslint.config.mts",
        "eslint.config.cts",
        ".eslintrc",
        ".eslintrc.js",
        ".eslintrc.cjs",
        ".eslintrc.yaml",
        ".eslintrc.yml",
        ".eslintrc.json",
    },
    package_keys = { "eslintConfig" },
    dependencies = {},
}

--- A prettier configuration.
---@type util.biome.Tool
M.prettier = {
    files        = {
        ".prettierrc",
        ".prettierrc.json",
        ".prettierrc.json5",
        ".prettierrc.yaml",
        ".prettierrc.yml",
        ".prettierrc.toml",
        ".prettierrc.js",
        ".prettierrc.cjs",
        ".prettierrc.mjs",
        ".prettierrc.ts",
        ".prettierrc.cts",
        ".prettierrc.mts",
        "prettier.config.js",
        "prettier.config.cjs",
        "prettier.config.mjs",
        "prettier.config.ts",
        "prettier.config.cts",
        "prettier.config.mts",
    },
    package_keys = { "prettier" },
    dependencies = {},
}

--- The evidence that a repository has chosen eslint or prettier. Only
--- configuration counts, not a dependency: a transitive `prettier` in
--- `package.json` says nothing about how the repository wants formatting.
---@type util.biome.Tool
M.incumbent = {
    files        = vim.list_extend(
        vim.list_extend({}, M.eslint.files),
        M.prettier.files
    ),
    package_keys = { "eslintConfig", "prettier" },
    dependencies = {},
}

--- The directory a buffer's search starts from: its file's directory, or
--- the working directory for a buffer with no file behind it.
---@param buf integer
---@return string dir
M.dir = function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then
        return vim.fn.getcwd()
    end
    return vim.fs.dirname(vim.fs.normalize(name))
end

--- The first directory above `dir` that is *not* searched: the parent of
--- its repository root, or nil outside a repository, which searches all
--- the way up to `/` as prettier and eslint themselves would.
---@param dir string
---@return string? stop
local stop_for = function(dir)
    local root = vim.fs.root(dir, ".git")
    return root and vim.fs.dirname(root) or nil
end

--- A value `vim.json.decode` can produce.
---@alias util.biome.Json boolean | number | string | table

--- Whether `pkg`, a decoded `package.json`, names the tool.
---@param pkg  table<string, util.biome.Json>
---@param tool util.biome.Tool
---@return boolean
local package_names = function(pkg, tool)
    for _, key in ipairs(tool.package_keys) do
        if pkg[key] ~= nil then
            return true
        end
    end
    for _, field in ipairs({ "dependencies", "devDependencies" }) do
        local value = pkg[field]
        if type(value) == "table" then
            ---@type table<string, util.biome.Json>
            local deps = value
            for _, dep in ipairs(tool.dependencies) do
                if deps[dep] ~= nil then
                    return true
                end
            end
        end
    end
    return false
end

--- Whether the repository holding `dir` configures `tool`, searching
--- from `dir` upward and no further than the repository root.
---@param dir  string
---@param tool util.biome.Tool
---@return boolean
M.configures = function(dir, tool)
    ---@type vim.fs.find.Opts
    local opts = {
        path   = dir,
        upward = true,
        stop   = stop_for(dir),
        type   = "file",
        limit  = math.huge,
    }

    if #vim.fs.find(tool.files, opts) > 0 then
        return true
    end

    for _, path in ipairs(vim.fs.find("package.json", opts)) do
        local text    = table.concat(vim.fn.readfile(path), "\n")
        local ok, pkg = pcall(vim.json.decode, text)
        if ok and type(pkg) == "table" and package_names(pkg, tool) then
            return true
        end
    end
    return false
end

--- Whether Biome owns a buffer: it does when the repository configures
--- Biome, or when it configures neither eslint nor prettier.
---@param buf integer
---@return boolean
M.enabled = function(buf)
    local dir = M.dir(buf)
    return M.configures(dir, M.biome) or not M.configures(dir, M.incumbent)
end

return M
