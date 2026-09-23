#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/mini.icons.lua
--
--

--
-- Local stand-in for nvim-mini/mini.icons's own opts type, so
-- lua/spec/mini.icons.lua still resolves once the plugin is pruned
-- from ~/.local/share/nvim/lazy. mini.nvim modules document their
-- config via `:h MiniIcons.config` rather than a formal `---@class`;
-- `style` is a closed 2-value option per that same help text.
--

---@meta

---@alias MiniIcons.Style "glyph" | "ascii"

---@class MiniIcons.Config
---@field style?              MiniIcons.Style
---@field default?            table<string, table>
---@field directory?          table<string, table>
---@field extension?          table<string, table>
---@field file?               table<string, table>
---@field filetype?           table<string, table>
---@field lsp?                table<string, table>
---@field os?                 table<string, table>
---@field use_file_extension? fun(ext: string, file: string): boolean | string
