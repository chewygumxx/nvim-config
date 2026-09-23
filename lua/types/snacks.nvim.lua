#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/snacks.nvim.lua
--
--

--
-- Local stand-in for folke/snacks.nvim's own opts type, so
-- lua/spec/snacks.nvim.lua still resolves once the plugin is pruned
-- from ~/.local/share/nvim/lazy. Only the top-level keys this repo
-- actually sets are declared; snacks.Config's real per-module schema
-- is far larger upstream. `snacks.dashboard.Item`/`Format.ctx` cover
-- only the fields lua/spec/snacks.nvim.lua's own dashboard `formats`
-- callbacks actually read; upstream's real `Item` also carries a
-- `[string]: any` catch-all (see that file's own comment).
--

---@meta

---@class snacks.dashboard.Item
---@field icon?    string
---@field key?     string
---@field desc?    string
---@field action?  string
---@field enabled? boolean
---@field section? string
---@field file?    string
---@field [string] any

---@class snacks.dashboard.Format.ctx
---@field width? integer

---@class snacks.Config
---@field animate?      table
---@field indent?       table
---@field input?        table
---@field picker?       table
---@field notifier?     table
---@field quickfile?    table
---@field scope?        table
---@field scroll?       table
---@field statuscolumn? table
---@field words?        table
---@field bigfile?      table
---@field dashboard?    table
---@field explorer?     table
