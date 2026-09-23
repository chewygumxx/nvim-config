#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/lazy.nvim.lua
--
--

--
-- Local stand-in for folke/lazy.nvim's own LazyPluginSpec/LazyPlugin/
-- LazySpec types, so every lua/spec/*.lua file (and lua/util/lazy.lua,
-- lua/util/spec.lua) still resolves once the plugin manager itself is
-- pruned from ~/.local/share/nvim/lazy. Transcribed from lazy.nvim's
-- lua/lazy/types.lua; internal-only pieces a spec author never touches
-- (LazyPluginState, LazyKeysSpec, LazyEventSpec, GitInfo, ...) are
-- collapsed to `table` rather than vendored in full. `opts_extend` is
-- a real, documented LazyPluginSpec field (lua/spec/blink.cmp.lua uses
-- it) that isn't declared anywhere in lazy.nvim's own types.lua; added
-- here since LazyPluginSpec isn't `(exact)`, so this only tightens,
-- never narrows, what upstream itself allows.
--

---@meta

---@alias PluginOpts table | fun(self: LazyPlugin, opts: table): table?

---@class LazyPluginHooks
---@field init?       fun(self: LazyPlugin)                                                       Will always be run
---@field deactivate? fun(self: LazyPlugin)                                                       Unload/Stop a plugin
---@field config?     fun(self: LazyPlugin, opts: table) | true                                   Will be executed when loading the plugin
---@field build?      false | string | fun(self: LazyPlugin) | (string | fun(self: LazyPlugin))[]
---@field opts?       PluginOpts

---@class LazyPluginRef
---@field branch?     string
---@field tag?        string
---@field commit?     string
---@field version?    string | boolean
---@field pin?        boolean
---@field submodules? boolean          Defaults to true

---@class LazyPluginBase
---@field [1]       string?
---@field name      string                   display name and name used for plugin config files
---@field main?     string                   Entry module that has setup & deactivate
---@field url?      string
---@field dir       string
---@field enabled?  boolean | fun(): boolean
---@field cond?     boolean | fun(): boolean
---@field optional? boolean                  If set, then this plugin will not be added unless it is added somewhere else
---@field lazy?     boolean
---@field priority? number                   Only useful for lazy=false plugins to force loading certain plugins first. Default priority is 50
---@field dev?      boolean                  If set, then link to the respective folder under your ~/projects
---@field rocks?    string[]
---@field virtual?  boolean                  virtual plugins won't be installed or added to the rtp.

---@class LazyPluginHandlers
---@field event? table<string, table>
---@field ft?    table<string, table>
---@field keys?  table<string, table>
---@field cmd?   table<string, string>

---@class LazyPlugin: LazyPluginBase, LazyPluginHandlers, LazyPluginHooks, LazyPluginRef
---@field dependencies? string[]
---@field specs?        string | string[] | LazyPluginSpec[]
---@field _?            table

---@class LazyPluginSpecHandlers
---@field event?  string[] | string | table[] | fun(self: LazyPlugin, event: string[]): string[]
---@field cmd?    string[] | string | fun(self: LazyPlugin, cmd: string[]): string[]
---@field ft?     string[] | string | fun(self: LazyPlugin, ft: string[]): string[]
---@field keys?   string | string[] | table[] | fun(self: LazyPlugin, keys: string[]): (string | table)[]
---@field module? false

---@class LazyPluginSpec: LazyPluginBase, LazyPluginSpecHandlers, LazyPluginHooks, LazyPluginRef
---@field name?         string                               display name and name used for plugin config files
---@field dir?          string
---@field dependencies? string | string[] | LazyPluginSpec[]
---@field specs?        string | string[] | LazyPluginSpec[]
---@field opts_extend?  string[]                             Dotted opts paths (e.g. "sources.default") to deep-extend instead of replace when merging specs

---@class LazySpecImport
---@field import   string | fun(): LazyPluginSpec spec module to import
---@field name?    string
---@field enabled? boolean | fun(): boolean
---@field cond?    boolean | fun(): boolean

---@alias LazySpec string | LazyPluginSpec | LazySpecImport | LazySpec[]
