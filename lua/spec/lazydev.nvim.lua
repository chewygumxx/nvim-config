#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/lazydev.nvim.lua
--
--

--
-- https://github.com/folke/lazydev.nvim
--

---@module "lazy"
---@module "lazydev"

---@type LazyPluginSpec
local M = {
    "folke/lazydev.nvim",
    ft = "lua",
    enabled = vim.fs.root(0, ".luarc.json") == nil,

    ---@type lazydev.Config
    opts = {},
    dependencies = {
        "wezterm-types",
    },
}

---@type lazydev.Library.spec[]
M.opts.library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },

    -- https://github.com/DrKJeff16/wezterm-types
    { path = "wezterm-types", mods = { "wezterm" } },
}

return M
