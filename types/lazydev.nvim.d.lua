#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/lazydev.nvim.lua
--
--

--
-- Local stand-in for folke/lazydev.nvim's own opts type, so
-- lua/spec/lazydev.nvim.lua still resolves once the plugin is pruned
-- from ~/.local/share/nvim/lazy.
--

---@meta

---@class lazydev.Library.spec
---@field path   string
---@field words? string[]
---@field mods?  string[]

---@class lazydev.Config
---@field library? lazydev.Library.spec[]
