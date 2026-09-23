#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/luasnip.d.lua
--
--

--
-- Local stand-in for L3MON4D3/LuaSnip's own opts type, so
-- lua/spec/luasnip.lua still resolves once the plugin is pruned from
-- ~/.local/share/nvim/lazy (the spec itself is already
-- `enabled = false`). LuaSnip's `setup()` has no formal top-level
-- LuaCATS class, so this name is invented locally.
--

---@meta

---@class cgxx.spec.luasnip.Config
