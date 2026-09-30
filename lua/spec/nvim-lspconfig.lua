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
-- Condemned in `lua/plugin.lua`, and kept only as the upstream the
-- configurations in `lsp/` were first ported from; nothing requires it.
-- Were it loaded, its own `lsp/<name>.lua` files would sit later on the
-- runtimepath than ours and so win every key both set, which is how
-- `shuck` once attached to bash buffers and `markdown_oxide` ran a
-- binary name its own file did not give.
-- https://github.com/neovim/nvim-lspconfig
--

---@module "lazy"

---@type LazyPluginSpec
local M = {
    "neovim/nvim-lspconfig",
}

return M
