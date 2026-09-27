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

--- The execution record `MiniTest.execute` writes onto a case as it runs
--- it. Declared rather than left to the `[string]` catch-all below, which
--- resolves to `any` and so fails the annotation-coverage gate at every
--- reader's call site rather than here.
---@class MiniTest.CaseExec
---@field state? string   Progress, ie. "Executing test" or "Pass"
---@field fails  string[] Assertion failures; empty until one happens
---@field notes  string[] `MiniTest.add_note` messages

--- A collected test case, as `collect.filter_cases` is handed one. `desc`
--- is the array of descriptions it was built from, outermost first: the
--- file, then each enclosing `describe`, then the `it`.
---@class MiniTest.Case
---@field desc     string[]
---@field exec?    MiniTest.CaseExec
---@field [string] any

--- What `execute.reporter` is set to. Every field is optional because
--- `MiniTest.execute` calls whichever are present and skips the rest, which
--- is what lets one reporter delegate to another and add a field of its
--- own.
---@class mini.test.Reporter
---@field start?  fun(cases: MiniTest.Case[])
---@field update? fun(case_num: integer)
---@field finish? fun()

---@class mini.test.GenReporter
---@field buffer fun(opts?: table): mini.test.Reporter
---@field stdout fun(opts?: table): mini.test.Reporter

---@class (exact) MiniTest.CollectOpts
---@field emulate_busted? boolean
---@field find_files?     fun(): string[]
---@field filter_cases?   fun(case: MiniTest.Case): boolean

---@class (exact) MiniTest.ExecuteOpts
---@field reporter?      mini.test.Reporter
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
---@field gen_reporter     mini.test.GenReporter
---@field setup            fun(config?: MiniTest.Config)
---@field run              fun(opts?: table)
---@field run_file         fun(file?: string, opts?: table)
---@field run_at_location  fun(location?: table, opts?: table)
---@field stop             fun(opts?: table)
---@field new_child_neovim fun(): mini.test.Child
---@field [string]         fun(...: any)
