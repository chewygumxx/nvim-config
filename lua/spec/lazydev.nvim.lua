#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/lazydev.nvim.lua
--
--

--
-- https://github.com/folke/lazydev.nvim
--

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
