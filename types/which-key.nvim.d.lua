#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/which-key.nvim.d.lua
--
--

--
-- Local stand-in for folke/which-key.nvim's own opts type, so
-- lua/spec/which-key.nvim.lua still resolves once the plugin is pruned
-- from ~/.local/share/nvim/lazy.
--

---@meta

---@class wk.Opts
---@field preset?    string
---@field delay?     integer | fun(ctx: table): integer
---@field filter?    fun(mapping: table): boolean
---@field spec?      table
---@field notify?    boolean
---@field triggers?  table
---@field defer?     fun(ctx: table): boolean
---@field plugins?   table
---@field win?       table
---@field layout?    table
---@field keys?      table
---@field sort?      string[]
---@field expand?    integer | fun(node: table): boolean
---@field replace?   table
---@field icons?     table
---@field show_help? boolean
---@field show_keys? boolean
---@field disable?   table
---@field debug?     boolean
