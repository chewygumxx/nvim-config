#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/nvim-lspconfig.lua
--
--

--
-- https://github.com/neovim/nvim-lspconfig
--

---@module "lazy"

---@type LazyPluginSpec
local M = {
    "neovim/nvim-lspconfig",
    lazy = false,
}

M.config = function()
    _G.setup_guard("util.lsp")
end

return M
