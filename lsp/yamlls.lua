#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/yamlls.lua
--
--

local lsp = require("util.lsp")

--- schemastore.nvim's catalog, or none before lazy.nvim has installed
--- it. `util.lsp.setup` evaluates this file at startup, so a bare
--- `require` would take the whole session down on a fresh machine.
---@type boolean, schemastore
local has_catalog, schemastore = pcall(require, "schemastore")

---@type table?
local schemas = has_catalog and schemastore.yaml.schemas() or nil

---@type vim.lsp.Config
local M = {
    cmd       = lsp.node_cmd("yaml-language-server", { "--stdio" }),
    filetypes = {
        "yaml",
        "yaml.docker-compose",
        "yaml.gitlab",
        "yaml.helm-values",
    },
    settings  = {
        -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
        redhat = { telemetry = { enabled = false } },
        yaml   = {
            -- Off by default in the server
            format = { enable = true },
            -- schemastore.nvim supplies the catalog instead, avoids a
            -- redundant fetch from yaml-language-server's own store.
            schemaStore = { enable = false, url = "" },
            schemas     = schemas,
        },
    },
}

---@param buf    integer
---@param on_dir fun(root_dir?: string)
---@return nil
M.root_dir = function(buf, on_dir)
    local root = vim.fs.root(buf, ".git")
    if lsp.node_available("yaml-language-server", root) then
        on_dir(root)
    end
end

--- The server only advertises formatting once a client asks for it, so
--- anything checking `supports_method("textDocument/formatting")` on
--- `LspAttach` would otherwise see false despite `format.enable` above.
---@param client vim.lsp.Client
---@return nil
M.on_init = function(client)
    client.server_capabilities.documentFormattingProvider = true
end

return M
