#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/schemastore.nvim.d.lua
--
--

--
-- Local stand-in for b0o/schemastore.nvim's own module type, so
-- lsp/jsonls.lua and lsp/yamlls.lua still resolve once the plugin is
-- pruned from ~/.local/share/nvim/lazy. `SchemaEntry` is transcribed
-- from schemastore.nvim/lua/schemastore/init.lua; `schemastore` itself
-- (the module's own local `M`) has no real upstream class name, so it's
-- declared fresh here, covering only the fields lsp/jsonls.lua and
-- lsp/yamlls.lua actually touch.
--

---@meta

---@class SchemaEntry
---@field name        string
---@field description string
---@field fileMatch   string | string[]
---@field url         string

---@class schemastore.json
---@field schemas fun(opts?: table): SchemaEntry[]

---@class schemastore.yaml
---@field schemas fun(opts?: table): table<string, string | string[]>

---@class schemastore
---@field json schemastore.json
---@field yaml schemastore.yaml
