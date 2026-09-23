#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/mini.files.lua
--
--

--
-- Local stand-in for nvim-mini/mini.files's own opts type, so
-- lua/spec/mini.files.lua still resolves once the plugin is pruned
-- from ~/.local/share/nvim/lazy. mini.nvim modules document their
-- config via `:h MiniFiles.config` rather than a formal `---@class`;
-- `fs_entry` mirrors the real (internal, un-namespaced) class found in
-- mini.files/lua/mini/files.lua.
--

---@meta

---@class (exact) fs_entry
---@field fs_type string one of "file" or "directory"
---@field path    string
---@field name    string

---@class (exact) MiniFiles.ContentOpts
---@field filter? fun(entry: fs_entry): boolean
---@field prefix? fun(entry: fs_entry): string, string?
---@field sort?   fun(entries: fs_entry[]): fs_entry[]

---@class (exact) MiniFiles.MappingsOpts
---@field close?       string
---@field go_in?       string
---@field go_in_plus?  string
---@field go_out?      string
---@field go_out_plus? string
---@field mark_goto?   string
---@field mark_set?    string
---@field reset?       string
---@field reveal_cwd?  string
---@field show_help?   string
---@field synchronize? string
---@field trim_left?   string
---@field trim_right?  string

---@class (exact) MiniFiles.OptionsOpts
---@field permanent_delete?        boolean
---@field use_as_default_explorer? boolean

---@class (exact) MiniFiles.WindowsOpts
---@field width_focus?   integer
---@field width_nofocus? integer
---@field width_preview? integer
---@field max_number?    integer
---@field preview?       boolean

---@class MiniFiles.Config
---@field content?  MiniFiles.ContentOpts
---@field mappings? MiniFiles.MappingsOpts
---@field options?  MiniFiles.OptionsOpts
---@field windows?  MiniFiles.WindowsOpts
