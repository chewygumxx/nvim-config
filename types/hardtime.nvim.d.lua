#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/hardtime.nvim.d.lua
--
--

--
-- Local stand-in for m4xshen/hardtime.nvim's options table, which carries
-- no LuaCATS annotations of its own, so this name is invented locally
-- rather than vendored. Only the keys `lua/spec/hardtime.nvim.lua` sets
-- are listed, plus the neighbours worth knowing exist; the plugin has
-- more.
--
-- The three key tables are `table<string, string[] | false>` rather than
-- `table<string, string[]>` on purpose. `false` is the only value that
-- switches an entry off through `opts`: the plugin's handler loop is
-- `if mode then vim.keymap.set(mode, key, ...)`, and its `setup` merges
-- with `vim.tbl_deep_extend("force", ...)`, which recurses whenever both
-- sides are tables. An empty or shorter list therefore leaves the
-- default's tail in place, while `false` replaces the value outright.
--

---@meta

---@alias cgxx.spec.hardtime.RestrictionMode "block" | "hint"

---@class cgxx.spec.hardtime.Config
---@field max_time?            integer                            Window in which repeats count, in ms
---@field max_count?           integer                            Repeats tolerated inside that window
---@field enabled?             boolean
---@field disable_mouse?       boolean                            Unmaps every mouse event when true
---@field hint?                boolean                            Suggests a better motion as you type
---@field notification?        boolean
---@field timeout?             integer                            Notification lifetime, in ms
---@field allow_different_key? boolean                            Whether a different key resets the count
---@field restriction_mode?    cgxx.spec.hardtime.RestrictionMode
---@field resetting_keys?      table<string, string[] | false>    Keys that clear the count, by mode
---@field restricted_keys?     table<string, string[] | false>    Keys counted towards the limit, by mode
---@field disabled_keys?       table<string, string[] | false>    Keys refused outright, by mode
---@field disabled_filetypes?  table<string, boolean>             Lua patterns, mapped to whether hardtime is off
---@field callback?            fun(text: string)                  Receives each notification
