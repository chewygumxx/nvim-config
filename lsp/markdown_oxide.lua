#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/markdown_oxide.lua
--
--

---@type vim.lsp.Config
local M = {
    cmd = { "markdown_oxide" },

    filetypes = { "markdown" },
    root_markers = { ".moxide.toml", ".git", "README", "index.md" },
}

---@type lsp.ClientCapabilities
local extra_capabilities = {
    workspace = {
        didChangeWatchedFiles = {
            dynamicRegistration = true,
        },
    },
}

---@type lsp.ClientCapabilities
M.capabilities = vim.tbl_deep_extend(
    "force",
    require("util.lsp").capabilities(),
    extra_capabilities
)

return M
