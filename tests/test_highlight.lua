#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_highlight.lua
--
--

--
-- `highlight.setup()` is deliberately the last thing `init.lua` calls, so
-- that it overwrites whatever the colorscheme and treesitter plugins have
-- just set. These cases assert what it writes, in the terms
-- `nvim_get_hl` answers in: a colour comes back as the integer its hex
-- literal denotes, and "none" comes back as the key simply being absent.
--

local highlight = require("highlight")
local eq        = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

--- Every group this module defines, with the attributes it sets. Absent
--- keys are exactly as meaningful as present ones: "bg = none" is how a
--- group is made transparent, and it reads back as no `bg` at all.
---
--- This list is also what `before_each` captures and `after_each` puts
--- back, so a group defined here and missing from it would keep this
--- config's definition for every test file that runs after this one.
--- "defines no group it does not document" is what keeps the two the same
--- set.
---@type table<string, vim.api.keyset.highlight>
local groups = {
    Normal                    = { fg = 0xcad6ff },
    Search                    = { fg = 0xe0e8ff, bg = 0x52408f, bold = true },
    Title                     = { fg = 0xcad6ff, bold = true },
    NonText                   = {},
    NormalFloat               = {},
    FloatBorder               = {},
    Underlined                = { underline = true },
    MatchParen                = { standout = true },
    ["@markup.strong"]        = { bold = true },
    ["@markup.underline"]     = { underline = true },
    ["@markup.strikethrough"] = { strikethrough = true },
}

--- Every group name `highlight.setup()` defines, observed at the call.
---
--- Read from the writes rather than by diffing `nvim_get_hl` afterwards:
--- most of these groups exist before `setup()` runs (a colorscheme has
--- already defined `Normal`), so presence proves nothing, and a definition
--- identical to what was already there would not show up in a diff at all.
---
--- Nothing is applied while the stub is installed, so this cannot leave
--- behind the undocumented group it exists to find.
---@return string[] names Sorted, one per write
local written = function()
    local real = vim.api.nvim_set_hl
    ---@type string[]
    local seen = {}

    -- Three parameters, matching the real arity: a narrower stub would
    -- retype the field for the whole workspace
    ---@param _ns  integer
    ---@param name string
    ---@param _val vim.api.keyset.highlight
    ---@return nil
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.api.nvim_set_hl = function(_ns, name, _val)
        table.insert(seen, name)
    end

    -- Restored before the assert, so a raising `setup` cannot leave the
    -- API stubbed for every case after this one
    local ok, err       = pcall(highlight.setup)
    vim.api.nvim_set_hl = real
    assert(ok, err)

    table.sort(seen)
    return seen
end

describe("highlight.setup", function()
    ---@type table<string, vim.api.keyset.get_hl_info>
    local original

    before_each(function()
        original = {}
        for name in pairs(groups) do
            original[name] = vim.api.nvim_get_hl(0, { name = name })
        end
        highlight.setup()
    end)

    after_each(function()
        for name, definition in pairs(original) do
            -- What `nvim_get_hl` answers is the same shape `nvim_set_hl`
            -- takes (its own documentation says so), but the two are
            -- declared as distinct types, so a round trip cannot be
            -- written without saying this
            ---@diagnostic disable-next-line: param-type-mismatch
            vim.api.nvim_set_hl(0, name, definition)
        end
    end)

    it("defines every group it documents", function()
        for name, want in pairs(groups) do
            local got = vim.api.nvim_get_hl(0, { name = name })
            eq({ name, got.fg }, { name, want.fg })
            eq({ name, got.bg }, { name, want.bg })
            eq({ name, got.bold }, { name, want.bold })
            eq({ name, got.underline }, { name, want.underline })
            eq({ name, got.strikethrough }, { name, want.strikethrough })
            eq({ name, got.standout }, { name, want.standout })
        end
    end)

    it("leaves the transparent groups without a background", function()
        -- The point of `bg = "none"`: these have to show the terminal's
        -- own background rather than the colorscheme's, including for
        -- floating windows, which otherwise stand out as solid boxes
        for _, name in ipairs({
            "Normal",
            "NonText",
            "NormalFloat",
            "FloatBorder",
        }) do
            local got = vim.api.nvim_get_hl(0, { name = name })
            eq({ name, got.bg }, { name, nil })
            eq({ name, got.ctermbg }, { name, nil })
        end
    end)

    it("defines no group it does not document", function()
        ---@type string[]
        local documented = {}
        for name in pairs(groups) do
            table.insert(documented, name)
        end
        table.sort(documented)

        eq(written(), documented)
    end)

    it("overwrites what a colorscheme left behind", function()
        -- The whole reason this runs last in `init.lua`
        vim.api.nvim_set_hl(0, "Normal", { fg = "#ff0000", bg = "#00ff00" })
        highlight.setup()

        local got = vim.api.nvim_get_hl(0, { name = "Normal" })
        eq(got.fg, 0xcad6ff)
        eq(got.bg, nil)
    end)
end)
