#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/nvim-lspconfig.lua
--
--

--
-- Bundled default vim.lsp.Config tables (lsp/*.lua) for hundreds of
-- servers, consumed by Neovim's native vim.lsp.config()/vim.lsp.enable().
-- Server install and enable is handled by spec/mason-lspconfig.nvim.lua;
-- this spec owns the shared setup: capabilities, diagnostics, keymaps.
-- https://github.com/neovim/nvim-lspconfig
--

---@module "lazy"
---@type LazySpec
local M = {
    "neovim/nvim-lspconfig",
    enabled = true,
    lazy    = false,
}

M.config = function()
    local lsp = _G.require_guard("util.lsp")
    if lsp then
        lsp.setup()
    end
end

return M
