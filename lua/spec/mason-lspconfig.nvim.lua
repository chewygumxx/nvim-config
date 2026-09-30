#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/mason-lspconfig.nvim.lua
--
--

--
-- Installs every server in ensure_installed through mason.nvim, and does
-- nothing else: `util.lsp.setup` enables exactly what `lsp/` configures,
-- which is also what makes servers work under Termux, where this plugin
-- is condemned.
-- https://github.com/mason-org/mason-lspconfig.nvim
--

---@module "lazy"
---@module "mason-lspconfig"

---@type LazyPluginSpec
local M = {
    "mason-org/mason-lspconfig.nvim",
    lazy         = false,
    dependencies = {
        "mason-org/mason.nvim",
    },
}

---@type MasonLspconfigSettings
M.opts = {
    ensure_installed = {
        "lua_ls", -- Lua

        -- TSX/JSX
        "vtsls",
        "eslint",
        "biome",

        -- Structured Data
        "jsonls",
        "yamlls",
        "tombi",

        -- Markdown
        "remark_ls",
        "marksman",
        "markdown_oxide",

        -- Shell
        "bashls",

        -- Python
        "pyright",

        -- SQL
        "sqls",

        -- Zsh
        "shuck",

        -- Tree-sitter queries
        "ts_query_ls",
    },
    automatic_enable = false,
}

return M
