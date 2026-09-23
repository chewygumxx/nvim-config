#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/mini.hipatterns.lua
--
--

--
-- Local stand-in for nvim-mini/mini.hipatterns's own opts type, so
-- lua/spec/mini.hipatterns.lua still resolves once the plugin is
-- pruned from ~/.local/share/nvim/lazy. mini.nvim modules document
-- their config via `:h MiniHipatterns.config` rather than a formal
-- `---@class`, so the field shapes below are transcribed from that
-- help text, not a vendored source annotation.
--

---@meta

---@class (exact) MiniHipatterns.HighlighterOpts
---@field pattern       string | string[] | fun(buf_id: integer): string | string[] | nil
---@field group         string | fun(buf_id: integer, match: string, data: table): string
---@field extmark_opts? table | fun(buf_id: integer, match: string, data: table): table

---@class MiniHipatterns.Config
---@field highlighters? table<string, MiniHipatterns.HighlighterOpts>

--
-- Local stand-in for the `require("mini.hipatterns")` module itself
-- (distinct from the MiniHipatterns.Config opts type above), covering
-- only the fields lua/spec/mini.hipatterns.lua actually touches.
--

---@class mini.hipatterns.gen_highlighter
---@field hex_color fun(opts?: table): MiniHipatterns.HighlighterOpts

---@class mini.hipatterns
---@field gen_highlighter mini.hipatterns.gen_highlighter
---@field setup           fun(config?: MiniHipatterns.Config)
