#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/nex_note.lua
--
--

--
-- Filetype-specific configuration for ~chewygumxx/nex.git notes, the
-- compound filetype `markdown.nex-note` that `util.nex` scaffolds and
-- `lua/filetype/init.lua` detects.
--
-- A note is Markdown first, so this inherits `filetype.markdown`'s own
-- settings wholesale rather than restating them: `M.config()` dispatches
-- to exactly one module per filetype, so without this a note would get
-- none of the Markdown heading palette when it is the first such buffer
-- of the session.
--

local M = {}

local markdown = require("filetype.markdown")

--- Markdown's own buffer-local options, plus the prose- and
--- structure-oriented ones a note wants on top.
---
--- The fold settings are what make the `foldlevel=3` in a note's own
--- modeline mean something: they resolve to Tree-sitter's heading folds,
--- so a note opens with its top three heading levels expanded and
--- anything deeper folded away. `vim.treesitter.foldexpr()` degrades to
--- "no folds" rather than erroring when the Markdown parser is absent.
---@type { [string]: number | string | boolean }
M.local_opts = vim.tbl_extend("force", markdown.local_opts, {
    -- Prose: soft-wrap on word boundaries, and give `gq` this repo's
    -- own 80 column target to reflow to
    linebreak = true,
    textwidth = 80,

    foldmethod = "expr",
    foldexpr   = "v:lua.vim.treesitter.foldexpr()",
    foldlevel  = 3,
})

--- Markdown's own highlight links, unchanged.
---
--- These are global (`nvim_set_hl(0, ...)`) rather than buffer-local, so
--- there is deliberately nothing note-specific here: anything added would
--- recolour every plain Markdown buffer too, which is not this filetype's
--- business. Notes are distinguished by their options above, not their
--- colours.
---@type { [string]: vim.api.keyset.highlight }
M.hlgroup_defs = markdown.hlgroup_defs

--- Markdown's own `setup()`, unchanged: the table keymaps are as welcome in
--- a note as in any other Markdown buffer, and a note gets them only
--- because it asks — `lua/filetype/init.lua` runs one module per filetype.
---@type fun(opts: vim.api.keyset.create_autocmd.callback_args)
M.setup = markdown.setup

return M
