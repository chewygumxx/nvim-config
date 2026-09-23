#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/mini.test.d.lua
--
--

--
-- Local stand-in for nvim-mini/mini.test's own opts type, so
-- lua/spec/mini.test.lua still resolves once the plugin is pruned
-- from ~/.local/share/nvim/lazy. mini.nvim modules document their
-- config via `:h MiniTest.config` rather than a formal `---@class`.
--

---@meta

---@class (exact) MiniTest.CollectOpts
---@field emulate_busted? boolean
---@field find_files?     fun(): string[]
---@field filter_cases?   fun(case: table): boolean

---@class (exact) MiniTest.ExecuteOpts
---@field reporter?      table
---@field stop_on_error? boolean

---@class MiniTest.Config
---@field collect?     MiniTest.CollectOpts
---@field execute?     MiniTest.ExecuteOpts
---@field script_path? string
---@field silent?      boolean

--
-- Local stand-in for the `require("mini.test")` module itself (distinct
-- from the MiniTest.Config opts type above), covering only the fields
-- tests/*.lua and scripts/minitest.lua actually touch.
--

---@class mini.test.Expect
---@field equality fun(left: any, right: any, opts?: table)

---@class mini.test
---@field expect          mini.test.Expect
---@field setup           fun(config?: MiniTest.Config)
---@field run             fun(opts?: table)
---@field run_file        fun(file?: string, opts?: table)
---@field run_at_location fun(location?: table, opts?: table)
---@field stop            fun(opts?: table)
---@field [string]        fun(...: any)
