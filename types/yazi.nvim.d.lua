#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/yazi.nvim.lua
--
--

--
-- Local stand-in for mikavilpas/yazi.nvim's own opts type, so
-- lua/spec/yazi.nvim.lua still resolves once the plugin is pruned from
-- ~/.local/share/nvim/lazy.
--

---@meta

---@class YaziConfig
---@field open_for_directories? boolean
---@field keymaps?              table
