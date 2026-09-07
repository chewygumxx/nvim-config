#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/lazydev.nvim.lua
--
--

--
-- https://github.com/folke/lazydev.nvim
--

---@module "lazy"
---@type LazySpec
local M = {
    "folke/lazydev.nvim",
    enabled = true,

    ft      = "lua",
    opts    = {},
}

M.opts.library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" }, },
    { path = "wezterm-types",      mods  = { "wezterm" }, },  -- https://github.com/DrKJeff16/wezterm-types
}

return M
