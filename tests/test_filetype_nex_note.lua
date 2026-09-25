#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_filetype_nex_note.lua
--
--

local nex_note = require("filetype.nex_note")
local markdown = require("filetype.markdown")
local eq       = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

describe("filetype.nex_note", function()
    it("inherits every one of markdown's buffer-local options", function()
        for opt, val in pairs(markdown.local_opts) do
            eq({ opt, nex_note.local_opts[opt] }, { opt, val })
        end
    end)

    it("adds the prose options markdown does not set", function()
        eq(nex_note.local_opts.linebreak, true)
        eq(nex_note.local_opts.textwidth, 80)
    end)

    it("folds by treesitter so the modeline's foldlevel applies", function()
        eq(nex_note.local_opts.foldmethod, "expr")
        eq(nex_note.local_opts.foldexpr, "v:lua.vim.treesitter.foldexpr()")
        eq(nex_note.local_opts.foldlevel, 3)
    end)

    it("reuses markdown's highlight links unchanged", function()
        eq(nex_note.hlgroup_defs, markdown.hlgroup_defs)
    end)

    it("delegates setup to markdown, so it gets the table keymaps", function()
        -- `lua/filetype/init.lua` runs one module per filetype, so a note
        -- reaches markdown's `setup()` only by naming it.
        eq(nex_note.setup, markdown.setup)
        eq(type(nex_note.setup), "function")
    end)

    it("leaves markdown's own options untouched", function()
        eq(markdown.local_opts.linebreak, nil)
        eq(markdown.local_opts.foldmethod, nil)
    end)
end)
