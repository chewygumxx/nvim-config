#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/markdown_table.lua
--
--

--
-- Formats GFM pipe tables and sets their per-column alignment.
--
-- Split in two halves. The upper half is pure: lines in, lines out, no
-- buffer and no cursor, which is what `tests/test_util_markdown_table.lua`
-- exercises. The lower half locates a table in a buffer, rewrites it, and
-- puts the cursor back.
--
-- Nothing here runs on save. `lua/spec/conform.nvim.lua` routes markdown
-- to prettier, which pads cells but will never author an alignment
-- marker; this module authors them, and prettier preserves what it finds.
-- Hence the single-space cell padding below: it is prettier's own, so the
-- two never undo each other.
--

local M = {}

---@alias cgxx.mdtable.Align "none" | "left" | "center" | "right"

---@class (exact) cgxx.mdtable.Table
---@field rows   string[][]           Trimmed cell text; row 1 is the header
---@field align  cgxx.mdtable.Align[] One entry per column
---@field prefix string               Leading indent / "> " quote marker

--- Narrowest renderable delimiter cell is ":-:", so no column may format
--- to less than three columns wide.
---@type integer
local MIN_WIDTH = 3

--
-- Pure: parsing
--

--- Splits a table row into trimmed cell text, discarding the outer pipes.
---
--- Scans character by character rather than matching a pattern: a cell may
--- legally contain an escaped pipe, and Lua patterns have no way to say
--- "a | not preceded by a backslash". Tree-sitter agrees with this reading
--- and keeps `\|` as cell content.
---
--- Outer pipes are optional in GFM (`a | b` is a table row), so a leading
--- or trailing empty cell is dropped only when the line actually has the
--- pipe that produced it.
---@param line string
---@return string[] cells
---@return string prefix  Indent and/or blockquote marker, to be replayed
M.split_cells = function(line)
    local prefix = line:match("^[%s>]*") or ""
    local body   = line:sub(#prefix + 1)

    ---@type string[]
    local cells = {}
    ---@type string
    local current = ""
    local i       = 1
    while i <= #body do
        local char = body:sub(i, i)
        if char == "\\" and i < #body then
            -- Keep the escape intact: it is part of the cell's source text
            current = current .. body:sub(i, i + 1)
            i       = i + 2
        elseif char == "|" then
            cells[#cells + 1] = vim.trim(current)
            current           = ""
            i                 = i + 1
        else
            current = current .. char
            i       = i + 1
        end
    end
    cells[#cells + 1] = vim.trim(current)

    -- A leading "|" yields an empty first cell, a trailing one an empty
    -- last cell. Both are artefacts of the outer pipes, not real columns.
    if body:match("^|") and cells[1] == "" then
        table.remove(cells, 1)
    end
    if body:match("|$") and cells[#cells] == "" then
        table.remove(cells)
    end

    return cells, prefix
end

--- Reads one delimiter cell's alignment from its colons.
---@param cell string
---@return cgxx.mdtable.Align
M.parse_align = function(cell)
    cell              = vim.trim(cell)
    local left, right = cell:match("^(:?)%-*(:?)$")
    if not left then
        return "none"
    end
    if left == ":" and right == ":" then
        return "center"
    elseif left == ":" then
        return "left"
    elseif right == ":" then
        return "right"
    end
    return "none"
end

--- True if the line is a delimiter row: every cell is dashes, optionally
--- colon-fenced, and there is at least one cell.
---@param line string
---@return boolean
M.is_delimiter_row = function(line)
    local cells = M.split_cells(line)
    if #cells == 0 then
        return false
    end
    for _, cell in ipairs(cells) do
        if not vim.trim(cell):match("^:?%-+:?$") then
            return false
        end
    end
    return true
end

--- Parses a table's own lines (delimiter row included) into a `Table`.
---
--- The delimiter row is deliberately dropped rather than stored: it is
--- fully described by `align`, and regenerating it on every render is what
--- reduces "align this column" to a single field assignment.
---
--- Rows are padded out to the widest row's cell count, so a table whose
--- rows disagree (a state you pass through while editing) still round
--- trips instead of losing cells.
---@param lines string[]
---@return cgxx.mdtable.Table
M.parse = function(lines)
    ---@type string[][]
    local rows = {}
    ---@type cgxx.mdtable.Align[]
    local align = {}
    ---@type string
    local prefix = ""

    for index, line in ipairs(lines) do
        local cells, line_prefix = M.split_cells(line)
        if index == 1 then
            prefix = line_prefix
        end

        -- Only the row directly under the header delimits; a later
        -- all-dashes row is data, however much it looks the part.
        if index == 2 and M.is_delimiter_row(line) then
            for column, cell in ipairs(cells) do
                align[column] = M.parse_align(cell)
            end
        else
            rows[#rows + 1] = cells
        end
    end

    ---@type integer
    local columns = #align
    for _, cells in ipairs(rows) do
        columns = math.max(columns, #cells)
    end
    for _, cells in ipairs(rows) do
        for column = #cells + 1, columns do
            cells[column] = ""
        end
    end
    for column = 1, columns do
        align[column] = align[column] or "none"
    end

    return { rows = rows, align = align, prefix = prefix }
end

--
-- Pure: rendering
--

--- Width of a cell as it will actually appear on screen.
---
--- `strdisplaywidth`, not `#text`: one CJK character is three bytes and
--- two columns, so a byte count aligns the pipes only for ASCII.
---@param text string
---@return integer
M.width = function(text)
    return vim.fn.strdisplaywidth(text)
end

--- Widest cell per column, floored at `MIN_WIDTH`.
---@param tbl cgxx.mdtable.Table
---@return integer[] widths
M.widths = function(tbl)
    ---@type integer[]
    local widths = {}
    for column = 1, #tbl.align do
        widths[column] = MIN_WIDTH
    end
    for _, cells in ipairs(tbl.rows) do
        for column, cell in ipairs(cells) do
            local seen     = widths[column] or MIN_WIDTH
            widths[column] = math.max(seen, M.width(cell))
        end
    end
    return widths
end

--- Pads cell text to `width` display columns per `align`.
---
--- "none" pads like "left": a table has to be a rectangle either way, and
--- the distinction lives in the delimiter row, not the cells.
---@param text  string
---@param width integer
---@param align cgxx.mdtable.Align
---@return string
M.pad = function(text, width, align)
    local slack = width - M.width(text)
    if slack <= 0 then
        return text
    end
    if align == "right" then
        return string.rep(" ", slack) .. text
    elseif align == "center" then
        local left = math.floor(slack / 2)
        return string.rep(" ", left) .. text .. string.rep(" ", slack - left)
    end
    return text .. string.rep(" ", slack)
end

--- Renders one delimiter cell, `width` display columns wide, so it lines up
--- with the data cells it sits under.
---
--- The colons count toward the width, so the dash run shrinks to make
--- room for them. `MIN_WIDTH` guarantees at least one dash survives.
---@param align cgxx.mdtable.Align
---@param width integer
---@return string
M.render_align = function(align, width)
    width = math.max(width, MIN_WIDTH)
    if align == "left" then
        return ":" .. string.rep("-", width - 1)
    elseif align == "right" then
        return string.rep("-", width - 1) .. ":"
    elseif align == "center" then
        return ":" .. string.rep("-", width - 2) .. ":"
    end
    return string.rep("-", width)
end

--- Renders a `Table` back to lines, pipes aligned.
---
--- Single-space cell padding, outer pipes on every line, and the delimiter
--- row spaced exactly like a data row: this is prettier's own shape,
--- verified against its output, so the format-on-save at
--- `lua/spec/conform.nvim.lua:40` is a no-op on anything rendered here.
--- Diverging would mean every write silently undid this module's work.
---@param tbl cgxx.mdtable.Table
---@return string[] lines
M.render = function(tbl)
    local widths = M.widths(tbl)

    ---@param cells string[]
    ---@return string
    local render_row = function(cells)
        ---@type string[]
        local out = {}
        for column = 1, #tbl.align do
            out[column] = M.pad(
                cells[column] or "",
                widths[column],
                tbl.align[column]
            )
        end
        return tbl.prefix .. "| " .. table.concat(out, " | ") .. " |"
    end

    ---@type string[]
    local delimiter = {}
    for column = 1, #tbl.align do
        delimiter[column] = M.render_align(tbl.align[column], widths[column])
    end

    ---@type string[]
    local lines = {}
    for index, cells in ipairs(tbl.rows) do
        lines[#lines + 1] = render_row(cells)
        if index == 1 then
            lines[#lines + 1] = tbl.prefix .. "| "
                .. table.concat(delimiter, " | ") .. " |"
        end
    end

    return lines
end

--
-- Pure: cursor bookkeeping
--

--- Locates a byte column within a row: which cell it falls in, and how far
--- into that cell's trimmed text it sits.
---
--- Paired with `M.cell_col` to carry the cursor across a reformat, which
--- moves every byte column in the line.
---@param line string
---@param col  integer 0-indexed byte column
---@return integer column 1-indexed; clamped into range
---@return integer offset 0-indexed byte offset into the trimmed cell
M.cell_at = function(line, col)
    local prefix = line:match("^[%s>]*") or ""
    local body   = line:sub(#prefix + 1)
    local at     = math.max(col - #prefix, 0)

    ---@type integer
    local column = body:match("^|") and 0 or 1
    ---@type integer
    local start = 0
    local i     = 1
    while i <= #body and i <= at do
        local char = body:sub(i, i)
        if char == "\\" and i < #body then
            i = i + 2
        elseif char == "|" then
            column = column + 1
            start  = i
            i      = i + 1
        else
            i = i + 1
        end
    end

    -- Offset is measured from the trimmed text, since that is the only
    -- part that survives a re-render.
    local raw    = body:sub(start + 1, at)
    local lead   = raw:match("^%s*") or ""
    local offset = math.max(#raw - #lead, 0)

    return math.max(column, 1), offset
end

--- Inverse of `M.cell_at`: the byte column `offset` bytes into `column`.
---@param line   string
---@param column integer 1-indexed
---@param offset integer 0-indexed byte offset into the trimmed cell
---@return integer col 0-indexed byte column
M.cell_col = function(line, column, offset)
    local prefix = line:match("^[%s>]*") or ""
    local body   = line:sub(#prefix + 1)

    ---@type integer
    local seen = body:match("^|") and 0 or 1
    ---@type integer
    local start = 0
    local i     = 1
    while i <= #body do
        local char = body:sub(i, i)
        if char == "\\" and i < #body then
            i = i + 2
        elseif char == "|" then
            if seen == column then
                break
            end
            seen  = seen + 1
            start = i
            i     = i + 1
        else
            i = i + 1
        end
    end
    if seen ~= column then
        return #prefix + #body
    end

    local cell = body:sub(start + 1, i - 1)
    local lead = cell:match("^%s*") or ""
    local at   = start + #lead + math.min(offset, #vim.trim(cell))

    return #prefix + at
end

return M
