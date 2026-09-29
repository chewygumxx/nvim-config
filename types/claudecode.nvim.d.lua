#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/claudecode.nvim.d.lua
--
--

--
-- Local stand-in for coder/claudecode.nvim's own opts type, so
-- lua/spec/claudecode.nvim.lua still resolves once the plugin is pruned
-- from ~/.local/share/nvim/lazy. Declares only the three options that
-- spec sets, each typed, so a value the plugin does not accept, such as
-- an unknown terminal provider, is reported rather than passed through.
--

---@meta

---@class (exact) PartialClaudeCodeConfig.Terminal
---@field provider? "auto" | "snacks" | "native" | "external" | "none"

---@class (exact) PartialClaudeCodeConfig.DiffOpts
---@field layout? "vertical" | "horizontal"

---@class (exact) PartialClaudeCodeConfig
---@field terminal?         PartialClaudeCodeConfig.Terminal
---@field focus_after_send? boolean
---@field diff_opts?        PartialClaudeCodeConfig.DiffOpts
