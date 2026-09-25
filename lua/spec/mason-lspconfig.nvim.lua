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
-- Bridges mason.nvim-installed servers to Neovim's native LSP client:
-- installs everything in ensure_installed, then calls vim.lsp.enable()
-- for them automatically.
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
        "neovim/nvim-lspconfig",
    },
}

---@type MasonLspconfigSettings
M.opts = {
    ensure_installed = {
        "lua_ls", -- Lua

        -- TSX/JSX
        "vtsls",
        "eslint",

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
    },
    automatic_enable = true,
}

return M
