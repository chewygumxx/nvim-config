#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/nvim-lint.d.lua
--
--

--
-- Local stand-in for mfussenegger/nvim-lint's own module type, so
-- lua/spec/nvim-lint.lua still resolves once the plugin is pruned
-- from ~/.local/share/nvim/lazy. `lint.Linter`/`lint.parse`/
-- `lint.try_lint.Opts` are transcribed from nvim-lint/lua/lint.lua;
-- `lint` itself (the module's own local `M`) has no real upstream
-- class name, so it's declared fresh here, covering only the fields
-- lua/spec/nvim-lint.lua actually touches.
--

---@meta

---@class lint.Linter
---@field name             string
---@field cmd              string
---@field args?            (string | fun(): string)[]
---@field stdin?           boolean
---@field append_fname?    boolean
---@field stream?          "stdout" | "stderr" | "both"
---@field ignore_exitcode? boolean
---@field env?             table
---@field cwd?             string
---@field parser           lint.parse

---@alias lint.parse fun(output: string, bufnr: number, linter_cwd: string): vim.Diagnostic[]

---@class lint.try_lint.Opts
---@field cwd?           string
---@field ignore_errors? boolean
---@field wrap_linter?   fun(linter: lint.Linter): lint.Linter

---@class lint
---@field linters_by_ft table<string, string[]>
---@field linters       table<string, lint.Linter>
---@field try_lint      fun(names?: string | string[], opts?: lint.try_lint.Opts)
