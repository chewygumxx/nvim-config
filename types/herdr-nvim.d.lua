#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/herdr-nvim.d.lua
--
--

--
-- Local stand-in for jtnovellis/herdr-nvim's own opts type, so
-- lua/spec/herdr-nvim.lua still resolves once the plugin is pruned
-- from ~/.local/share/nvim/lazy. herdr-nvim ships no LuaCATS
-- annotations at all, so this name is invented locally.
--

---@meta

--- `keymaps` is the only field this repository sets, and the only one it
--- can: the plugin hardcodes the `<leader>a` prefix in its own table with
--- no option to move it, so `false` (define none) plus explicit `keys` in
--- the spec is how those mappings end up anywhere else.
---@class cgxx.spec.herdr.Config
---@field keymaps? boolean | "force" Whether the plugin defines its own mappings
