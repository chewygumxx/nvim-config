#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_markdown_table.lua
--
--

local mdtable = require("util.markdown_table")
local eq      = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

--- `render(parse(lines))`, the round trip both halves are specified by.
---@param lines string[]
---@return string[]
local format = function(lines)
    return mdtable.render(mdtable.parse(lines))
end

describe("util.markdown_table.split_cells", function()
    it("drops the outer pipes and trims each cell", function()
        local cells, prefix = mdtable.split_cells("|  a |  bb  | ccc|")
        eq(cells, { "a", "bb", "ccc" })
        eq(prefix, "")
    end)

    it("keeps an escaped pipe as one cell, not two", function()
        eq(mdtable.split_cells([[| x \| y | 2 |]]), { [[x \| y]], "2" })
    end)

    it("accepts a row without outer pipes", function()
        eq(mdtable.split_cells("a | b"), { "a", "b" })
    end)

    it("preserves interior empty cells but not the outer artefacts", function()
        eq(mdtable.split_cells("| a | | c |"), { "a", "", "c" })
    end)

    it("reports the indent and blockquote marker as prefix", function()
        local _, indent = mdtable.split_cells("    | a | b |")
        eq(indent, "    ")
        local _, quote = mdtable.split_cells("> | a | b |")
        eq(quote, "> ")
    end)
end)

describe("util.markdown_table.parse_align", function()
    it("reads each of the four alignments from its colons", function()
        eq(mdtable.parse_align("---"), "none")
        eq(mdtable.parse_align(":--"), "left")
        eq(mdtable.parse_align("--:"), "right")
        eq(mdtable.parse_align(":-:"), "center")
    end)

    it("treats a non-delimiter cell as unaligned", function()
        eq(mdtable.parse_align("abc"), "none")
        eq(mdtable.parse_align(""), "none")
    end)
end)

describe("util.markdown_table.is_delimiter_row", function()
    it("accepts a row of dashes, colon-fenced or not", function()
        eq(mdtable.is_delimiter_row("|---|:--|--:|:-:|"), true)
    end)

    it("rejects a row carrying data", function()
        eq(mdtable.is_delimiter_row("| a | b |"), false)
        eq(mdtable.is_delimiter_row("| --- | b |"), false)
    end)
end)

describe("util.markdown_table.pad", function()
    it("pads left, right and centre to the given width", function()
        eq(mdtable.pad("a", 5, "none"), "a    ")
        eq(mdtable.pad("a", 5, "left"), "a    ")
        eq(mdtable.pad("a", 5, "right"), "    a")
        eq(mdtable.pad("a", 5, "center"), "  a  ")
    end)

    it("gives an odd centre remainder to the right", function()
        eq(mdtable.pad("a", 4, "center"), " a  ")
    end)

    it("measures display width, not bytes", function()
        -- Three characters, nine bytes, six display columns: a byte-based
        -- implementation would over-pad this by three spaces.
        eq(mdtable.width("日本語"), 6)
        eq(mdtable.pad("日本語", 8, "none"), "日本語  ")
    end)

    it("never truncates a cell wider than the column", function()
        eq(mdtable.pad("abcdef", 3, "none"), "abcdef")
    end)
end)

describe("util.markdown_table.render_align", function()
    it("spends the width on dashes, colons included", function()
        eq(mdtable.render_align("none", 5), "-----")
        eq(mdtable.render_align("left", 5), ":----")
        eq(mdtable.render_align("right", 5), "----:")
        eq(mdtable.render_align("center", 5), ":---:")
    end)

    it("keeps a dash at the floor width of three", function()
        eq(mdtable.render_align("center", 3), ":-:")
        eq(mdtable.render_align("left", 3), ":--")
    end)
end)

describe("util.markdown_table.render", function()
    it("squares up a ragged table and rebuilds the delimiter row", function()
        eq(format({
            "| a | bb | ccc |",
            "|---|---|---|",
            "| 1 | 2 | 3 |",
            "| xxxx | | z |",
        }), {
            "| a    | bb  | ccc |",
            "| ---- | --- | --- |",
            "| 1    | 2   | 3   |",
            "| xxxx |     | z   |",
        })
    end)

    it("pads cells the way each column's alignment asks", function()
        eq(format({
            "| a | bb | ccc |",
            "|:--|---:|:---:|",
            "| 1 | 2 | 3 |",
        }), {
            "| a   |  bb | ccc |",
            "| :-- | --: | :-: |",
            "| 1   |   2 |  3  |",
        })
    end)

    it("is idempotent: formatting its own output changes nothing", function()
        local once  = format({ "| a | bb |", "|:--|--:|", "| 1 | 2 |" })
        local twice = format(once)
        eq(twice, once)
    end)

    it("aligns a CJK column by display width", function()
        local lines = {
            "| name | v |",
            "|---|---|",
            "| 日本語 | 1 |",
            "| ab | 2 |",
        }
        eq(format(lines), {
            "| name   | v   |",
            "| ------ | --- |",
            "| 日本語 | 1   |",
            "| ab     | 2   |",
        })
    end)

    it("round trips an escaped pipe without splitting the cell", function()
        eq(format({ "| a | b |", "|---|---|", [[| x \| y | 2 |]] }), {
            "| a      | b   |",
            "| ------ | --- |",
            [[| x \| y | 2   |]],
        })
    end)

    it("replays the blockquote marker on every line", function()
        eq(
            format({ "> | a | b |", "> |---|---|", "> | 1 | 2 |" }),
            { "> | a   | b   |", "> | --- | --- |", "> | 1   | 2   |" }
        )
    end)

    it("replays a list indent on every line", function()
        eq(
            format({ "  | a | b |", "  |---|--:|", "  | 1 | 2 |" }),
            { "  | a   |   b |", "  | --- | --: |", "  | 1   |   2 |" }
        )
    end)

    it("supplies the delimiter row a half-typed table lacks", function()
        eq(
            format({ "| a | b |", "| 1 | 2 |" }),
            { "| a   | b   |", "| --- | --- |", "| 1   | 2   |" }
        )
    end)

    it("gives outer pipes to a table written without them", function()
        eq(
            format({ "a | b", "--|--", "1 | 2" }),
            { "| a   | b   |", "| --- | --- |", "| 1   | 2   |" }
        )
    end)

    it("squares up rows whose cell counts disagree", function()
        local tbl = mdtable.parse({ "| a | b | c |", "|---|---|", "| 1 |" })
        eq(#tbl.align, 3)
        eq(tbl.rows[2], { "1", "", "" })
    end)

    it("only reads row two as the delimiter", function()
        -- An all-dashes row further down is data, however much it looks
        -- the part, so it must survive the round trip as a cell.
        local tbl = mdtable.parse({
            "| a | b |",
            "|---|---|",
            "| --- | --- |",
        })
        eq(#tbl.rows, 2)
        eq(tbl.rows[2], { "---", "---" })
    end)
end)

describe("util.markdown_table cursor mapping", function()
    it("locates the cell and offset under a byte column", function()
        local line = "| a | bb |"
        eq({ mdtable.cell_at(line, 2) }, { 1, 0 }) -- on "a"
        eq({ mdtable.cell_at(line, 6) }, { 2, 0 }) -- on first "b"
        eq({ mdtable.cell_at(line, 7) }, { 2, 1 }) -- on second "b"
    end)

    it("inverts itself, so a cell keeps the cursor across a reflow", function()
        local line = "| a | bb |"
        for col = 0, #line - 1 do
            local column, offset = mdtable.cell_at(line, col)
            local back           = mdtable.cell_col(line, column, offset)
            -- Round tripping lands in the same cell it started in. The
            -- tuple carries `col` so a failure names the column at fault.
            local again = mdtable.cell_at(line, back)
            eq({ col, again }, { col, column })
        end
    end)

    it("carries an offset onto a rewritten, wider line", function()
        local before = "| a | bb |"
        local after  = "| aaaa | bb  |"
        -- "b" moves from byte 6 to byte 9 when column one widens.
        eq(mdtable.cell_col(after, mdtable.cell_at(before, 6)), 9)
    end)

    it("clamps past the end of a cell rather than overshooting", function()
        -- Offset 9 is well past "a"; it must stop inside the same cell.
        eq(mdtable.cell_col("| a | bb |", 1, 9), 3)
    end)

    it("handles a row without outer pipes", function()
        eq({ mdtable.cell_at("a | b", 0) }, { 1, 0 })
        eq({ mdtable.cell_at("a | b", 4) }, { 2, 0 })
        eq(mdtable.cell_col("a | b", 2, 0), 4)
    end)
end)

describe("util.markdown_table buffer operations", function()
    ---@type integer
    local bufnr

    --- A scratch markdown buffer holding `lines`, current in the window so
    --- the cursor calls under test have somewhere to land.
    ---
    --- Re-assigning 'undolevels' to itself breaks undo, so filling the
    --- fixture is its own undo block. Without it a single `undo` would
    --- step past the reflow all the way back to the empty buffer.
    ---@param lines string[]
    ---@return nil
    local scratch = function(lines)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.bo[bufnr].undolevels = vim.bo[bufnr].undolevels
        vim.bo[bufnr].modified   = false
    end

    ---@return string[]
    local buffer = function()
        return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    end

    --- Swaps `vim.notify` for one that drops anything below ERROR, keeping
    --- `enable`/`disable`'s progress messages out of the reporter.
    ---@return fun(msg: string, level?: integer) original
    local quieten = function()
        local notify = vim.notify
        vim.notify   = function(msg, level)
            if level and level >= vim.log.levels.ERROR then
                notify(msg, level)
            end
        end
        return notify
    end

    before_each(function()
        bufnr                  = vim.api.nvim_create_buf(false, true)
        vim.bo[bufnr].filetype = "markdown"
        vim.api.nvim_set_current_buf(bufnr)
    end)

    after_each(function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("formats the table the cursor is in", function()
        scratch({ "# doc", "", "| a | bb |", "|---|---|", "| 1 | 2 |" })
        vim.api.nvim_win_set_cursor(0, { 3, 2 })
        eq(mdtable.format(bufnr), true)
        eq(buffer(), {
            "# doc",
            "",
            "| a   | bb  |",
            "| --- | --- |",
            "| 1   | 2   |",
        })
    end)

    it("leaves the cursor in the cell it started in", function()
        scratch({ "| a | bb |", "|---|---|", "| 1 | 2 |" })
        -- On the first "b" of "bb", byte 6 before the reflow.
        vim.api.nvim_win_set_cursor(0, { 1, 6 })
        mdtable.format(bufnr)
        local cursor = vim.api.nvim_win_get_cursor(0)
        eq(cursor[1], 1)
        eq(
            vim.api
                .nvim_buf_get_lines(bufnr, 0, 1, false)
                [1]
                :sub(cursor[2] + 1, cursor[2] + 1),
            "b"
        )
    end)

    it("writes nothing when the table is already formatted", function()
        scratch({ "| a   | b   |", "| --- | --- |", "| 1   | 2   |" })
        vim.api.nvim_win_set_cursor(0, { 1, 2 })
        -- The no-op guard: an identical set_lines would still dirty the
        -- buffer and push an undo state.
        eq(mdtable.format(bufnr), false)
        eq(vim.bo[bufnr].modified, false)
    end)

    it("reflows as a single undo step", function()
        scratch({ "| a | bb | ccc |", "|---|---|---|", "| 1 | 2 | 3 |" })
        vim.api.nvim_win_set_cursor(0, { 1, 2 })
        mdtable.format(bufnr)
        vim.cmd("silent undo")
        eq(buffer(), { "| a | bb | ccc |", "|---|---|---|", "| 1 | 2 | 3 |" })
    end)

    it("will not touch a table inside a fenced code block", function()
        scratch({ "```", "| a | b |", "|---|---|", "| 1 | 2 |", "```" })
        eq(mdtable.in_code_block(bufnr, 1), true)
        vim.api.nvim_win_set_cursor(0, { 2, 2 })
        eq(mdtable.format(bufnr), false)
        eq(buffer(), { "```", "| a | b |", "|---|---|", "| 1 | 2 |", "```" })
    end)

    it("formats a half-typed table Tree-sitter cannot see", function()
        -- No delimiter row, so this is not a `pipe_table` node at all;
        -- only the line-scan fallback finds it.
        scratch({ "| a | b |", "| 1 | 2 |" })
        vim.api.nvim_win_set_cursor(0, { 1, 2 })
        eq(mdtable.format(bufnr), true)
        eq(buffer(), { "| a   | b   |", "| --- | --- |", "| 1   | 2   |" })
    end)

    it("sets the alignment of the column under the cursor", function()
        scratch({ "| a | bb |", "|---|---|", "| 1 | 2 |" })
        vim.api.nvim_win_set_cursor(0, { 1, 6 })
        eq(mdtable.set_align("right", bufnr), true)
        eq(buffer(), {
            "| a   |  bb |",
            "| --- | --: |",
            "| 1   |   2 |",
        })
    end)

    it("centres and clears an alignment it previously set", function()
        scratch({ "| a | bb |", "|---|--:|", "| 1 | 2 |" })
        vim.api.nvim_win_set_cursor(0, { 1, 6 })
        mdtable.set_align("center", bufnr)
        eq(vim.api.nvim_buf_get_lines(bufnr, 1, 2, false), { "| --- | :-: |" })
        mdtable.set_align("none", bufnr)
        eq(vim.api.nvim_buf_get_lines(bufnr, 1, 2, false), { "| --- | --- |" })
    end)

    it("formats every table in the buffer, whatever their heights", function()
        scratch({
            "| a | b |",
            "|---|---|",
            "| 1 | 2 |",
            "",
            "| ccc | d |",
            "|---|---|",
            "| 1 | 2 |",
            "| 3 | 4 |",
        })
        eq(mdtable.format_buffer(bufnr), 2)
        eq(buffer(), {
            "| a   | b   |",
            "| --- | --- |",
            "| 1   | 2   |",
            "",
            "| ccc | d   |",
            "| --- | --- |",
            "| 1   | 2   |",
            "| 3   | 4   |",
        })
    end)

    it("skips fenced tables when formatting the whole buffer", function()
        scratch({
            "| a | b |",
            "|---|---|",
            "| 1 | 2 |",
            "",
            "```",
            "| c | d |",
            "|---|---|",
            "```",
        })
        eq(mdtable.format_buffer(bufnr), 1)
        eq(vim.api.nvim_buf_get_lines(bufnr, 4, 8, false), {
            "```",
            "| c | d |",
            "|---|---|",
            "```",
        })
    end)

    it("reports the table's extent, and nothing for a plain line", function()
        scratch({ "text", "", "| a | b |", "|---|---|", "| 1 | 2 |", "" })
        eq({ mdtable.table_range(bufnr, 3) }, { 2, 4 })
        eq({ mdtable.table_range(bufnr, 0) }, {})
    end)

    it("is opt-in per buffer for reformat-as-you-edit", function()
        local notify = quieten()

        -- The autocmd does nothing until a buffer asks for it, so that
        -- typing a table is never reflowed out from under you.
        eq(vim.b[bufnr].cgxx_mdtable, nil)
        mdtable.toggle(bufnr)
        eq(vim.b[bufnr].cgxx_mdtable, true)
        mdtable.toggle(bufnr)
        eq(vim.b[bufnr].cgxx_mdtable, false)

        vim.notify = notify
    end)

    it("reflows on edit once enabled, and not before", function()
        local notify = quieten()
        mdtable.autocmd()

        local ragged = { "| a   | b   |", "| --- | --- |", "| 1111 | 2 |" }
        scratch(ragged)
        vim.api.nvim_win_set_cursor(0, { 3, 2 })

        -- Disabled: the autocmd sees the buffer and declines.
        vim.cmd("doautocmd TextChanged")
        eq(buffer(), ragged)

        mdtable.enable(bufnr)
        vim.cmd("doautocmd TextChanged")
        eq(buffer(), {
            "| a    | b   |",
            "| ---- | --- |",
            "| 1111 | 2   |",
        })

        -- And stops again on request.
        mdtable.disable(bufnr)
        scratch(ragged)
        vim.api.nvim_win_set_cursor(0, { 3, 2 })
        vim.cmd("doautocmd TextChanged")
        eq(buffer(), ragged)

        vim.notify = notify
    end)

    it("reflows on leaving insert mode too", function()
        local notify = quieten()
        mdtable.autocmd()
        mdtable.enable(bufnr)

        scratch({ "| a | bb |", "|---|---|", "| 1 | 2 |" })
        vim.api.nvim_win_set_cursor(0, { 1, 2 })
        vim.cmd("doautocmd InsertLeave")
        eq(buffer(), { "| a   | bb  |", "| --- | --- |", "| 1   | 2   |" })

        vim.notify = notify
    end)

    it("attaches its keymaps buffer-locally, not globally", function()
        mdtable.keymap(bufnr)
        ---@type table<string, true>
        local lhs  = {}
        local maps = vim.api.nvim_buf_get_keymap(bufnr, "n")
        for _, map in ipairs(maps) do
            lhs[map.lhs or ""] = true
        end
        -- `\` is this config's leader, per `lua/keymap/init.lua`.
        eq(lhs["\\tf"], true)
        eq(lhs["\\tr"], true)
        eq(lhs["\\tt"], true)
    end)

    it("offers every action it dispatches as a completion", function()
        eq(mdtable.complete(), {
            "buffer",
            "center",
            "disable",
            "enable",
            "format",
            "left",
            "none",
            "right",
            "toggle",
        })
    end)
end)
