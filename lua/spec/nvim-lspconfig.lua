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
---@type LazySpec
local M = {
    "neovim/nvim-lspconfig",
    enabled = true,
    lazy    = false,
}

M.config = function()
    local lsp = _G.require_guard("util.lsp")
    if lsp and lsp.setup then
        lsp.setup()
    end
end

return M
