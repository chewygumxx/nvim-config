#!/bin/false
-- vim: expandtab:shiftwidth=4:ft=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/luasnip.lua
--
--

--
-- Snippet Engine
-- https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md
--


---@module "lazy"
---@type   LazySpec
local M = {
    "L3MON4D3/LuaSnip",
    enabled = false,
    version = "v2.5.*",
    build   = "make install_jsregexp",
}

M.opts = { }


return M
