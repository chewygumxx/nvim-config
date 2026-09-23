#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/telescope.nvim.lua
--
--

--
-- Local stand-in for nvim-telescope/telescope.nvim's own opts type, so
-- lua/spec/telescope.nvim.lua and lua/spec/telescope-undo.lua (which
-- both build a table ultimately passed to `require("telescope").setup()`)
-- still resolve once the plugin is pruned from ~/.local/share/nvim/lazy.
-- Core telescope ships no formal top-level LuaCATS class for this
-- (`telescope_popup_options` etc. are for pickers, not root setup), so
-- this name is invented locally.
--

---@meta

---@class cgxx.spec.telescope.Opts
---@field extensions? table<string, table>

--
-- Local stand-in for the `require("telescope.builtin")` module itself
-- (distinct from the setup opts type above), covering only the fields
-- lua/spec/telescope.nvim.lua actually touches.
--

---@class telescope.builtin
---@field loclist  fun(opts?: table)
---@field quickfix fun(opts?: table)
