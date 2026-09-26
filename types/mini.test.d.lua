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

--
-- The managed child process (`:h MiniTest.new_child_neovim()`), which
-- tests/test_init.lua drives. Only the methods it calls are declared: the
-- real object also proxies the whole `vim.api`/`vim.fn`/`vim.o` surface
-- into the child, which the `[string]` catch-all below already covers for
-- the module and is not worth restating field by field here.
--

---@class mini.test.Child
---@field start    fun(args?: string[], opts?: table)
---@field restart  fun(args?: string[], opts?: table)
---@field stop     fun()
---@field lua      fun(str: string, args?: table): any
---@field lua_get  fun(str: string, args?: table): any
---@field [string] any

---@class mini.test
---@field expect           mini.test.Expect
---@field setup            fun(config?: MiniTest.Config)
---@field run              fun(opts?: table)
---@field run_file         fun(file?: string, opts?: table)
---@field run_at_location  fun(location?: table, opts?: table)
---@field stop             fun(opts?: table)
---@field new_child_neovim fun(): mini.test.Child
---@field [string]         fun(...: any)
