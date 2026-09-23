#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/conform.nvim.d.lua
--
--

--
-- Local stand-in for stevearc/conform.nvim's own opts type, so
-- lua/spec/conform.nvim.lua still resolves once the plugin is pruned
-- from ~/.local/share/nvim/lazy. Transcribed in full from
-- conform.nvim/lua/conform/types.lua, whose own `(exact)` choices this
-- mirrors (the root `conform.setupOpts` is deliberately left open
-- upstream; its nested structs are not).
--

---@meta

---@alias conform.LspFormatOpts "never" | "first" | "last" | "prefer" | "fallback"

---@class (exact) conform.Range
---@field start integer[]
---@field end   integer[]

---@class (exact) conform.Context
---@field buf        integer
---@field filename   string
---@field dirname    string
---@field range?     conform.Range
---@field shiftwidth integer

---@class (exact) conform.RangeContext: conform.Context
---@field range conform.Range

---@class (exact) conform.JobFormatterConfig
---@field command         string | fun(self: conform.JobFormatterConfig, ctx: conform.Context): string
---@field args?           string | string[] | fun(self: conform.JobFormatterConfig, ctx: conform.Context): string | string[]
---@field range_args?     fun(self: conform.JobFormatterConfig, ctx: conform.RangeContext): string | string[]
---@field cwd?            fun(self: conform.JobFormatterConfig, ctx: conform.Context): nil | string
---@field require_cwd?    boolean
---@field stdin?          boolean
---@field tmpfile_format? string
---@field condition?      fun(self: conform.JobFormatterConfig, ctx: conform.Context): boolean
---@field exit_codes?     integer[]
---@field env?            table<string, string> | fun(self: conform.JobFormatterConfig, ctx: conform.Context): table<string, string>
---@field options?        table

---@class (exact) conform.FormatterConfigOverride: conform.JobFormatterConfig
---@field inherit?      boolean | string
---@field command?      string | fun(self: conform.FormatterConfigOverride, ctx: conform.Context): string
---@field prepend_args? string | string[] | fun(self: conform.FormatterConfigOverride, ctx: conform.Context): string | string[]
---@field append_args?  string | string[] | fun(self: conform.FormatterConfigOverride, ctx: conform.Context): string | string[]
---@field format?       fun(self: conform.FormatterConfigOverride, ctx: conform.Context, lines: string[], callback: fun(err: nil | string, new_lines: nil | string[]))
---@field options?      table

---@class (exact) conform.DefaultFormatOpts
---@field timeout_ms?       integer
---@field lsp_format?       conform.LspFormatOpts
---@field quiet?            boolean
---@field stop_after_first? boolean

---@class (exact) conform.DefaultFiletypeFormatOpts: conform.DefaultFormatOpts
---@field id?                 integer
---@field name?               string
---@field filter?             fun(client: table): boolean
---@field formatting_options? table

---@class conform.FiletypeFormatterInternal: conform.DefaultFiletypeFormatOpts
---@field [integer] string

---@alias conform.FiletypeFormatter conform.FiletypeFormatterInternal | fun(bufnr: integer): conform.FiletypeFormatterInternal

---@class (exact) conform.FormatOpts
---@field timeout_ms?         integer
---@field bufnr?              integer
---@field async?              boolean
---@field dry_run?            boolean
---@field undojoin?           boolean
---@field formatters?         string[]
---@field lsp_format?         conform.LspFormatOpts
---@field stop_after_first?   boolean
---@field quiet?              boolean
---@field range?              conform.Range
---@field id?                 integer
---@field name?               string
---@field filter?             fun(client: table): boolean
---@field formatting_options? table

---@class conform.setupOpts
---@field formatters_by_ft?     table<string, conform.FiletypeFormatter>
---@field format_on_save?       conform.FormatOpts | fun(bufnr: integer): nil | conform.FormatOpts
---@field default_format_opts?  conform.DefaultFormatOpts
---@field format_after_save?    conform.FormatOpts | fun(bufnr: integer): nil | conform.FormatOpts
---@field log_level?            integer
---@field notify_on_error?      boolean
---@field notify_no_formatters? boolean
---@field formatters?           table<string, conform.FormatterConfigOverride | fun(bufnr: integer): nil | conform.FormatterConfigOverride>
