#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/nvim-notify.lua
--
--

--
-- Local stand-in for rcarriga/nvim-notify's own opts type, so
-- lua/spec/nvim-notify.lua still resolves once the plugin is pruned
-- from ~/.local/share/nvim/lazy. `notify.Renderer`/`notify.StageName`
-- are transcribed from the closed name lists documented in
-- nvim-notify/lua/notify/render/init.lua and its `BUILTIN_STAGES`
-- table in nvim-notify/lua/notify/config/init.lua.
--

---@meta

---@alias notify.Renderer "default"|"minimal"|"simple"|"compact"|"wrapped-compact"|"wrapped-default"
---@alias notify.StageName "fade"|"slide"|"slide_out"|"fade_in_slide_out"|"static"

---@class (exact) notify.Highlights
---@field title  string
---@field icon   string
---@field border string
---@field body   string

---@class notify.Config
---@field merge_duplicates?  boolean
---@field background_colour? string
---@field fps?               integer
---@field icons?             table<string, string>
---@field level?             integer | string
---@field minimum_width?     integer
---@field render?            notify.Renderer | fun(buf: integer, notification: table, highlights: notify.Highlights, config: table): table
---@field stages?            notify.StageName | fun(): table
---@field time_formats?      table<string, string>
---@field timeout?           integer
---@field top_down?          boolean
