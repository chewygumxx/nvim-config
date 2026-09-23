#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/starry.d.lua
--
--

--
-- Local stand-in for ray-x/starry.nvim's own opts type, so
-- lua/spec/starry.lua still resolves once the plugin is pruned from
-- ~/.local/share/nvim/lazy. starry.nvim ships no LuaCATS annotations,
-- so this name is invented locally; the ThemeName enum is transcribed
-- from lua/spec/starry.lua's own comment (sourced from
-- starry/util.lua:81).
--

---@meta

---@alias cgxx.spec.starry.ThemeName
--- | "dark_solar"
--- | "darker"
--- | "deep ocean"
--- | "dracula"
--- | "dracula_blood"
--- | "earlysummer"
--- | "emerald"
--- | "mariana"
--- | "mariana_lighter"
--- | "middlenight_blue"
--- | "monokai"
--- | "monokai_lighter"
--- | "moonlight"
--- | "oceanic"
--- | "palenight"
--- | "ukraine"

---@class (exact) cgxx.spec.starry.ItalicsOpts
---@field comments?  boolean
---@field strings?   boolean
---@field keywords?  boolean
---@field functions? boolean
---@field variables? boolean

---@class (exact) cgxx.spec.starry.ContrastOpts
---@field enable?    boolean
---@field terminal?  boolean
---@field filetypes? table<string, boolean>

---@class (exact) cgxx.spec.starry.TextContrastOpts
---@field lighter? boolean
---@field darker?  boolean

---@class (exact) cgxx.spec.starry.DisableOpts
---@field background?  boolean
---@field term_colors? boolean
---@field eob_lines?   boolean

---@class (exact) cgxx.spec.starry.StyleOpts
---@field name?            cgxx.spec.starry.ThemeName
---@field disable?         string[]
---@field fix?             boolean
---@field darker_contrast? boolean
---@field daylight_switch? boolean
---@field deep_black?      boolean

---@class cgxx.spec.starry.Config
---@field border?        boolean
---@field hide_eob?      boolean
---@field italics?       cgxx.spec.starry.ItalicsOpts
---@field contrast?      cgxx.spec.starry.ContrastOpts
---@field text_contrast? cgxx.spec.starry.TextContrastOpts
---@field disable?       cgxx.spec.starry.DisableOpts
---@field theme?         boolean | cgxx.spec.starry.ThemeName
---@field style?         cgxx.spec.starry.StyleOpts
