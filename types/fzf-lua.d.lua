#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/fzf-lua.d.lua
--
--

--
-- Local stand-in for ibhagwan/fzf-lua's own opts type, so
-- lua/spec/fzf-lua.lua still resolves once the plugin is pruned from
-- ~/.local/share/nvim/lazy. Upstream's real `fzf-lua.Config` extends a
-- large `fzf-lua.config.Defaults`; this repo sets nothing, so only the
-- bare name is declared. `fzf-lua` (the real, un-namespaced module
-- class name) covers only the picker functions lua/util/lsp.lua
-- actually calls via `require("fzf-lua")`.
--

---@meta

---@class fzf-lua.Config

---@class fzf-lua
---@field diagnostics_workspace fun(opts?: table)
---@field diagnostics_document  fun(opts?: table)
---@field lsp_document_symbols  fun(opts?: table)
---@field lsp_workspace_symbols fun(opts?: table)
