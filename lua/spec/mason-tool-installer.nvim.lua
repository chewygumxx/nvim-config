#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/mason-tool-installer.nvim.lua
--
--

--
-- Bridges mason.nvim-installed non-LSP tools (formatters, linters, DAP
-- adapters) to ensure_installed.
-- Analgous to mason-lspconfig for LSP servers.
-- https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
--

---@module "lazy"
---@module "mason-tool-installer"

---@type LazyPluginSpec
local M = {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    enabled      = vim.env.TERMUX_VERSION == nil,
    lazy         = false,
    dependencies = {
        "mason-org/mason.nvim",
    },

    ---@type MasonToolInstallerSettings
    opts = {
        ensure_installed = {
            "stylua",
            "luafmt",
            "prettier",
            "tombi",
            "selene",
            "ruff",
            "shellcheck",
            "shfmt",

            -- DAP adapters
            "debugpy",
            "bash-debug-adapter",
            "js-debug-adapter",
            "local-lua-debugger-vscode",
        },
    },
}

return M
