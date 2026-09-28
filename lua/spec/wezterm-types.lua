#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/wezterm-types.lua
--
--

--
-- https://github.com/DrKJeff16/wezterm-types
--

---@module "lazy"

---@type LazyPluginSpec
local M = {
    "DrKJeff16/wezterm-types",
    -- Types only, read by lazydev.nvim's `library` entry through the
    -- plugin's directory. lazydev lists it as a dependency, which is all
    -- the loading it needs; `ft = "lua"` loaded it into every Lua buffer.
    lazy    = true,
    version = false,
}

return M
