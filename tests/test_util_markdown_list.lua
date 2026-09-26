#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_markdown_list.lua
--
--

--
-- `util.markdown_list` exists because Neovim deliberately will not continue
-- a Markdown list: `$VIMRUNTIME/ftplugin/markdown.vim` removes the `r` and
-- `o` `formatoptions` flags, and the `comments` leaders it defines carry
-- `f`, so a newline indents without repeating the marker. The parsing is
-- therefore the whole feature, and the cases below are mostly about it.
--
-- The buffer-driven cases run in a real split rather than an unattached
-- buffer, because `M.open` and `M.split` read and write the cursor, which
-- needs a window. Each one leaves insert mode again: `startinsert!` is what
-- makes the mapping usable, and a suite that shares one Neovim would
-- otherwise hand the next file a process sitting in insert.
--

local eq = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

local list = require("util.markdown_list")

--- Every form a list item is recognised in, with what it should parse to.
---@type { line: string, kind: string, marker: string, indent: string, checkbox: string?, sibling: string } []
local forms = {
    {
        line = "- item",
        kind = "bullet",
        marker = "-",
        indent = "",
        sibling = "- ",
    },
    {
        line = "* item",
        kind = "bullet",
        marker = "*",
        indent = "",
        sibling = "* ",
    },
    {
        line = "+ item",
        kind = "bullet",
        marker = "+",
        indent = "",
        sibling = "+ ",
    },
    {
        line = "  - nested",
        kind = "bullet",
        marker = "-",
        indent = "  ",
        sibling = "  - ",
    },
    {
        line = "- [ ] todo",
        kind = "bullet",
        marker = "-",
        indent = "",
        checkbox = " ",
        sibling = "- [ ] ",
    },
    -- A done item continues as an open one: the alternative is a new line
    -- that claims to be finished before it has been written
    {
        line = "- [x] done",
        kind = "bullet",
        marker = "-",
        indent = "",
        checkbox = "x",
        sibling = "- [ ] ",
    },
    {
        line = "    - [ ] deep",
        kind = "bullet",
        marker = "-",
        indent = "    ",
        checkbox = " ",
        sibling = "    - [ ] ",
    },
    {
        line = "1. first",
        kind = "ordered",
        marker = "1",
        indent = "",
        sibling = "2. ",
    },
    {
        line = "3) third",
        kind = "ordered",
        marker = "3",
        indent = "",
        sibling = "4) ",
    },
    {
        line = "9. ninth",
        kind = "ordered",
        marker = "9",
        indent = "",
        sibling = "10. ",
    },
    {
        line = "1. [ ] numbered todo",
        kind = "ordered",
        marker = "1",
        indent = "",
        checkbox = " ",
        sibling = "2. [ ] ",
    },
    {
        line = "> quoted",
        kind = "quote",
        marker = ">",
        indent = "",
        sibling = "> ",
    },
    {
        line = ">> deeper",
        kind = "quote",
        marker = ">>",
        indent = "",
        sibling = ">> ",
    },
}

--- Lines that are not list items, and must not be treated as one.
---@type string[]
local prose = {
    "plain text",
    "# heading",
    "",
    "    indented code",
    "text - with a dash",
    "[link]: https://example.invalid",
}

describe("util.markdown_list.parse", function()
    for _, form in ipairs(forms) do
        it("reads " .. form.line, function()
            local item = assert(list.parse(form.line), form.line)
            eq({
                form.line,
                item.kind,
                item.marker,
                item.indent,
                item.checkbox,
            },
                {
                    form.line,
                    form.kind,
                    form.marker,
                    form.indent,
                    form.checkbox,
                })
        end)
    end

    it("reads nothing into a line that is not an item", function()
        ---@type string[]
        local misread = {}
        for _, line in ipairs(prose) do
            if list.parse(line) ~= nil then
                table.insert(misread, line)
            end
        end
        eq(misread, {})
    end)

    it("keeps the content apart from the marker", function()
        local item = assert(list.parse("  - [x] the content"))
        eq(item.content, "the content")
    end)
end)

describe("util.markdown_list.sibling", function()
    for _, form in ipairs(forms) do
        it("continues " .. form.line, function()
            local item = assert(list.parse(form.line), form.line)
            eq({ form.line, list.sibling(item) }, { form.line, form.sibling })
        end)
    end

    it("holds an ordered marker when told not to advance", function()
        local item = assert(list.parse("7. seventh"))
        eq(list.sibling(item, false), "7. ")
    end)

    it("advances an ordered marker by default", function()
        local item = assert(list.parse("7. seventh"))
        eq(list.sibling(item, true), "8. ")
    end)
end)

describe("util.markdown_list.empty", function()
    it("recognises a marker with nothing after it", function()
        ---@type string[]
        local occupied = {}
        for _, line in ipairs({ "- ", "1. ", "> ", "  - [ ] ", "* " }) do
            local item = assert(list.parse(line), line)
            if not list.empty(item) then
                table.insert(occupied, line)
            end
        end
        eq(occupied, {})
    end)

    it("recognises a marker with content after it", function()
        ---@type string[]
        local blank = {}
        for _, form in ipairs(forms) do
            local item = assert(list.parse(form.line), form.line)
            if list.empty(item) then
                table.insert(blank, form.line)
            end
        end
        eq(blank, {})
    end)
end)

describe("util.markdown_list buffer actions", function()
    ---@type integer
    local buf = 0

    before_each(function()
        -- A real split: `M.open` and `M.split` read and write the cursor,
        -- which an unattached buffer has none of
        vim.cmd("new")
        buf = vim.api.nvim_get_current_buf()
    end)

    after_each(function()
        vim.cmd("stopinsert")
        vim.cmd("bwipeout!")
    end)

    --- Writes lines into the split and puts the cursor at row/column.
    ---@param lines  string[]
    ---@param row    integer
    ---@param column integer
    ---@return nil
    local given = function(lines, row, column)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_win_set_cursor(0, { row, column })
    end

    --- Every line in the split.
    ---@return string[] lines
    local written = function()
        return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    end

    it("opens a continuation below the item", function()
        given({ "- first" }, 1, 7)
        eq(list.open(true, buf), true)
        eq(written(), { "- first", "- " })
    end)

    it("opens a continuation above the item", function()
        given({ "- first" }, 1, 7)
        eq(list.open(false, buf), true)
        eq(written(), { "- ", "- first" })
    end)

    it("advances an ordered marker below but not above", function()
        given({ "4. fourth" }, 1, 9)
        eq(list.open(true, buf), true)
        eq(written(), { "4. fourth", "5. " })

        given({ "4. fourth" }, 1, 9)
        eq(list.open(false, buf), true)
        eq(written(), { "4. ", "4. fourth" })
    end)

    it("declines a line that is not an item", function()
        given({ "plain prose" }, 1, 5)
        eq(list.open(true, buf), false)
        -- Nothing written: the caller feeds the unmapped key instead
        eq(written(), { "plain prose" })
    end)

    it("ends the list on an item with no content", function()
        given({ "- written", "- " }, 2, 2)
        eq(list.open(true, buf), true)
        eq(written(), { "- written", "" })
    end)

    it("splits an item at the cursor", function()
        given({ "- before and after" }, 1, 9)
        eq(list.split(buf), true)
        eq(written(), { "- before ", "- and after" })
    end)

    it("splits a checkbox item into another open one", function()
        -- Split mid-content rather than at the end of the line: in normal
        -- mode `nvim_win_set_cursor` clamps the column to the last
        -- character, so a column of `#line` does not mean what it would in
        -- insert mode, where this mapping actually runs
        given({ "  - [x] alpha beta" }, 1, 14)
        eq(list.split(buf), true)
        eq(written(), { "  - [x] alpha ", "  - [ ] beta" })
    end)

    it("ends the list when splitting an empty item", function()
        given({ "- written", "- " }, 2, 2)
        eq(list.split(buf), true)
        eq(written(), { "- written", "", "" })
    end)

    it("leaves the cursor after the new marker", function()
        given({ "  - [ ] todo" }, 1, 12)
        eq(list.split(buf), true)
        eq(vim.api.nvim_win_get_cursor(0), { 2, 8 })
    end)

    it("attaches its mappings to the buffer", function()
        list.keymap(buf)

        ---@type string[]
        local missing = {}
        for _, map in ipairs({
            { mode = "n", lhs = "o" },
            { mode = "n", lhs = "O" },
            { mode = "i", lhs = "<M-CR>" },
        }) do
            ---@type table<string, any>[]
            local mapped = vim.api.nvim_buf_get_keymap(buf, map.mode)
            -- Compared against `lhs`, the readable form, and not `lhsraw`,
            -- which is the keycode: `vim.keycode("<M-CR>")` matches neither
            local found = false
            for _, entry in ipairs(mapped) do
                if entry.lhs == map.lhs then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(missing, map.mode .. " " .. map.lhs)
            end
        end
        eq(missing, {})
    end)
end)
