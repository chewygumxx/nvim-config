#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/jsonls.lua
--
--

local lsp = require("util.lsp")

--- schemastore.nvim's catalog, or none before lazy.nvim has installed
--- it. `util.lsp.setup` evaluates this file at startup, so a bare
--- `require` would take the whole session down on a fresh machine.
---@type boolean, schemastore
local has_catalog, schemastore = pcall(require, "schemastore")

---@type table?
local schemas = has_catalog and schemastore.json.schemas() or nil

---@type vim.lsp.Config
local M = {
    cmd          = lsp.node_cmd("vscode-json-language-server", { "--stdio" }),
    filetypes    = { "json", "jsonc" },
    init_options = { provideFormatter = true },
    settings     = {
        json = {
            schemas  = schemas,
            validate = { enable = true },
        },
    },
}

---@param buf    integer
---@param on_dir fun(root_dir?: string)
---@return nil
M.root_dir = function(buf, on_dir)
    local root = vim.fs.root(buf, ".git")
    if lsp.node_available("vscode-json-language-server", root) then
        on_dir(root)
    end
end

return M
