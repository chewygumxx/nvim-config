#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/nvim-dap.d.lua
--
--

--
-- Local stand-in for mfussenegger/nvim-dap's, mfussenegger/nvim-dap-ui's,
-- and jbyuki/one-small-step-for-vimkind's module types, so
-- lua/spec/nvim-dap.lua, lua/spec/nvim-dap-ui.lua, and
-- lua/spec/one-small-step-for-vimkind.lua still resolve once the plugins
-- are pruned from ~/.local/share/nvim/lazy. `dap.Adapter`/
-- `dap.Configuration`/`dap.utils.pick_process.Opts` are transcribed from
-- nvim-dap/lua/dap.lua and nvim-dap/lua/dap/utils.lua; `dap.listeners`
-- covers only the event names lua/spec/nvim-dap-ui.lua actually
-- registers, not nvim-dap's full real event/request list.
--

---@meta

---@class dap.Adapter
---@field type                      string
---@field id?                       string
---@field options?                  table
---@field enrich_config?            fun(config: dap.Configuration, on_config: fun(config: dap.Configuration))
---@field reverse_request_handlers? table

---@class dap.Configuration
---@field type     string
---@field request  "launch" | "attach"
---@field name     string
---@field [string] any

---@class dap.listeners.before
---@field attach?           table<string, fun()>
---@field launch?           table<string, fun()>
---@field event_terminated? table<string, fun()>
---@field event_exited?     table<string, fun()>

---@class dap.listeners
---@field before dap.listeners.before

---@class dap.repl
---@field toggle fun()

---@class dap
---@field adapters          table<string, dap.Adapter | fun(callback: fun(adapter: dap.Adapter), config: dap.Configuration)>
---@field configurations    table<string, dap.Configuration[]>
---@field listeners         dap.listeners
---@field repl              dap.repl
---@field toggle_breakpoint fun()
---@field continue          fun()
---@field step_over         fun()
---@field step_into         fun()
---@field step_out          fun()
---@field terminate         fun()

---@class dap.utils.Proc
---@field pid  integer
---@field name string

---@class dap.utils.pick_process.Opts
---@field filter? string | fun(proc: dap.utils.Proc): boolean
---@field label?  fun(proc: dap.utils.Proc): string
---@field prompt? string

---@class dap.utils
---@field pick_process fun(opts?: dap.utils.pick_process.Opts): integer

---@class dapui
---@field setup  fun(user_config?: table)
---@field open   fun(args?: table)
---@field close  fun(args?: table)
---@field toggle fun(args?: table)
