#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/luasnip.lua
--
--

--
-- Snippet Engine
-- https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md
--

---@module "lazy"

---@type LazyPluginSpec
local M = {
    "L3MON4D3/LuaSnip",
    version = "v2.5.*",
    build   = "make install_jsregexp",

    opts = {},
}

return M
