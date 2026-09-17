#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/schemastore.nvim.lua
--
--

--
-- JSON/YAML schema catalog, consumed by lsp/jsonls.lua and lsp/yamlls.lua.
-- Pure Lua data, no setup() call; lazy.nvim loads it on first require().
-- https://github.com/b0o/schemastore.nvim
--

---@module "lazy"
---@type LazySpec
local M = {
    "b0o/schemastore.nvim",
    lazy = true,
}

return M
