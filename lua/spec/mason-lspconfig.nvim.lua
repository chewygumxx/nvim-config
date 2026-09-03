#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/mason-lspconfig.nvim.lua
--
--

--
-- Bridges mason.nvim-installed servers to Neovim's native LSP client:
-- installs everything in ensure_installed, then calls vim.lsp.enable()
-- for them automatically. To add a server later, add its name below.
-- https://github.com/mason-org/mason-lspconfig.nvim
--

---@module "lazy"
---@type LazySpec
local M = {
    "mason-org/mason-lspconfig.nvim",
    enabled = true,
    lazy    = false,
    dependencies = {
        "mason-org/mason.nvim",
        "neovim/nvim-lspconfig",
    },
}

M.opts = {
    ensure_installed = {
        "lua_ls",
        -- bashls, pyright, yamlls, taplo, ... : one line each.
    },
    automatic_enable = true,
}

return M
