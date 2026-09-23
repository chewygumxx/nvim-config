#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/blink.cmp.d.lua
--
--

--
-- Local stand-in for saghen/blink.cmp's own opts type, so
-- lua/spec/blink.cmp.lua still resolves once the plugin is pruned from
-- ~/.local/share/nvim/lazy. Transcribed from
-- blink.cmp/lua/blink/cmp/config/*.lua. `(exact)` is only used where
-- the real class's full top-level field set was confirmed from source;
-- fields this repo doesn't set are still declared (typed loosely) so
-- exactness doesn't reject legitimate future config.
--

---@meta

---@alias blink.cmp.KeymapPreset "none" | "inherit"

---@alias blink.cmp.KeymapCommand
--- | 'fallback'
--- | 'fallback_to_mappings'
--- | 'show'
--- | 'show_and_insert'
--- | 'show_and_insert_or_accept_single'
--- | 'hide'
--- | 'cancel'
--- | 'accept'
--- | 'accept_and_enter'
--- | 'select_and_accept'
--- | 'select_accept_and_enter'
--- | 'select_prev'
--- | 'select_next'
--- | 'insert_prev'
--- | 'insert_next'
--- | 'show_documentation'
--- | 'hide_documentation'
--- | 'scroll_documentation_up'
--- | 'scroll_documentation_down'
--- | 'show_signature'
--- | 'hide_signature'
--- | 'scroll_signature_up'
--- | 'scroll_signature_down'
--- | 'snippet_forward'
--- | 'snippet_backward'
--- | (fun(cmp: table): boolean | string | nil)

---@class blink.cmp.KeymapConfig
---@field preset?  blink.cmp.KeymapPreset
---@field [string] blink.cmp.KeymapCommand[]

---@alias blink.cmp.FuzzyImplementationType "prefer_rust_with_warning" | "prefer_rust" | "rust" | "lua"

---@class (exact) blink.cmp.FuzzyFrecencyConfig
---@field enabled?        boolean
---@field path?           string
---@field unsafe_no_lock? boolean

---@class (exact) blink.cmp.PrebuiltBinariesProxyConfig
---@field from_env? boolean
---@field url?      string

---@class (exact) blink.cmp.PrebuiltBinariesConfig
---@field download?                boolean
---@field ignore_version_mismatch? boolean
---@field force_version?           string
---@field force_system_triple?     string
---@field extra_curl_args?         string[]
---@field proxy?                   blink.cmp.PrebuiltBinariesProxyConfig

---@class (exact) blink.cmp.FuzzyConfig
---@field implementation?     blink.cmp.FuzzyImplementationType
---@field max_typos?          number | fun(keyword: string): number
---@field use_frecency?       boolean
---@field use_unsafe_no_lock? boolean
---@field use_proximity?      boolean
---@field sorts?              table[]
---@field frecency?           blink.cmp.FuzzyFrecencyConfig
---@field prebuilt_binaries?  blink.cmp.PrebuiltBinariesConfig

---@class (exact) blink.cmp.SourceProviderConfig
---@field module              string
---@field name?               string
---@field enabled?            boolean | fun(): boolean
---@field opts?               table
---@field async?              boolean | fun(ctx: table): boolean
---@field timeout_ms?         number | fun(ctx: table): number
---@field transform_items?    fun(ctx: table, items: table[]): table[]
---@field should_show_items?  boolean | fun(ctx: table, items: table[]): boolean
---@field max_items?          number | fun(ctx: table, items: table[]): number
---@field min_keyword_length? number | fun(ctx: table): number
---@field fallbacks?          string[] | fun(ctx: table, enabled_sources: string[]): string[]
---@field score_offset?       number | fun(ctx: table, enabled_sources: string[]): number
---@field deduplicate?        table
---@field override?           table

---@class (exact) blink.cmp.SourceConfig
---@field default?            string[] | fun(): string[]
---@field per_filetype?       table<string, table>
---@field transform_items?    fun(ctx: table, items: table[]): table[]
---@field min_keyword_length? number | fun(ctx: table): number
---@field providers?          table<string, blink.cmp.SourceProviderConfig>

---@class (exact) blink.cmp.AppearanceConfig
---@field highlight_ns?            number
---@field use_nvim_cmp_as_default? boolean
---@field nerd_font_variant?       "mono" | "normal"
---@field kind_icons?              table<string, string>

---@class (exact) blink.cmp.CompletionDocumentationWindowConfig
---@field min_width?          number
---@field max_width?          number
---@field max_height?         number
---@field desired_min_width?  number
---@field desired_min_height? number
---@field border?             string | string[]
---@field winblend?           number
---@field winhighlight?       string
---@field scrollbar?          boolean
---@field direction_priority? table

---@class (exact) blink.cmp.CompletionDocumentationConfig
---@field auto_show?               boolean
---@field auto_show_delay_ms?      number
---@field update_delay_ms?         number
---@field treesitter_highlighting? boolean
---@field draw?                    fun(opts: table)
---@field window?                  blink.cmp.CompletionDocumentationWindowConfig

---@class (exact) blink.cmp.CompletionListSelectionConfig
---@field preselect?   boolean | fun(ctx: table): boolean
---@field auto_insert? boolean | fun(ctx: table): boolean

---@class (exact) blink.cmp.CompletionListCycleConfig
---@field from_bottom? boolean
---@field from_top?    boolean

---@class (exact) blink.cmp.CompletionListConfig
---@field max_items? number
---@field selection? blink.cmp.CompletionListSelectionConfig
---@field cycle?     blink.cmp.CompletionListCycleConfig

---@class (exact) blink.cmp.CompletionConfig
---@field keyword?       table
---@field trigger?       table
---@field list?          blink.cmp.CompletionListConfig
---@field accept?        table
---@field menu?          table
---@field documentation? blink.cmp.CompletionDocumentationConfig
---@field ghost_text?    table

---@class (exact) blink.cmp.Config
---@field enabled?    fun(): boolean | "force"
---@field keymap?     blink.cmp.KeymapConfig
---@field completion? blink.cmp.CompletionConfig
---@field fuzzy?      blink.cmp.FuzzyConfig
---@field sources?    blink.cmp.SourceConfig
---@field signature?  table
---@field snippets?   table
---@field appearance? blink.cmp.AppearanceConfig
---@field cmdline?    table
---@field term?       table
