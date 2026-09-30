#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/biome.lua
--
--

--
-- Biome starts where the repository configures it, and also as the
-- fallback where it configures neither eslint nor prettier. `util.biome`
-- makes that call so that `lua/spec/conform.nvim.lua` makes the same one.
--

local biome = require("util.biome")
local lsp   = require("util.lsp")

---@type vim.lsp.Config
local M = {
    cmd                = lsp.node_cmd("biome", { "lsp-proxy" }),
    filetypes          = {
        "astro",
        "css",
        "graphql",
        "html",
        "javascript",
        "javascriptreact",
        "json",
        "jsonc",
        "svelte",
        "typescript",
        "typescriptreact",
        "vue",
    },
    workspace_required = true,
}

--- A Biome config is a root in its own right, below a lockfile and above
--- `.git`, since Biome resolves nested configs itself and one server per
--- monorepo is what it expects.
---@type (string | string[])[]
local root_markers = {
    vim.list_extend({ "deno.lock" }, lsp.js_lockfiles),
    biome.biome.files,
    { ".git" },
}

---@param buf    integer
---@param on_dir fun(root_dir?: string)
---@return nil
M.root_dir = function(buf, on_dir)
    if not biome.enabled(buf) then
        return
    end
    local root = vim.fs.root(biome.dir(buf), root_markers) or vim.fn.getcwd()
    if lsp.node_available("biome", root) then
        on_dir(root)
    end
end

return M
