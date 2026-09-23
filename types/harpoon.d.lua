#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/harpoon.lua
--
--

--
-- Local stand-in for ThePrimeagen/harpoon's own opts and module types,
-- so lua/spec/harpoon.lua still resolves once the plugin is pruned from
-- ~/.local/share/nvim/lazy. `Harpoon`/`HarpoonUI`/`HarpoonList` are
-- transcribed from harpoon/lua/harpoon/{init,ui,list}.lua, covering
-- only the methods lua/spec/harpoon.lua actually calls.
--

---@meta

---@class HarpoonPartialConfig

---@class HarpoonList
---@field add    fun(self: HarpoonList, item?: table)
---@field select fun(self: HarpoonList, index: integer)
---@field next   fun(self: HarpoonList, opts?: table)
---@field prev   fun(self: HarpoonList, opts?: table)

---@class HarpoonUI
---@field toggle_quick_menu fun(self: HarpoonUI, list?: HarpoonList, opts?: table)

---@class Harpoon
---@field ui    HarpoonUI
---@field list  fun(self: Harpoon, name?: string): HarpoonList
---@field setup fun(self: Harpoon, partial_config?: HarpoonPartialConfig): Harpoon
