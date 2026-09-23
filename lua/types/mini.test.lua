#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/mini.test.lua
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
