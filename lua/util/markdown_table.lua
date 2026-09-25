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

--
-- Buffer: locating a table
--

--- Node types Tree-sitter's markdown grammar uses for a fenced block. A
--- run of pipes inside one of these is code, not a table, and rewriting it
--- would corrupt the buffer.
---@type table<string, true>
local FENCE_NODES = {
    fenced_code_block   = true,
    code_fence_content  = true,
    indented_code_block = true,
}

--- The markdown node at a position, or nil when Tree-sitter cannot say.
---
--- Deliberately not `vim.treesitter.get_node`: that returns nil until
--- something has already parsed the buffer, so on a buffer nothing has
--- highlighted yet — a scratch buffer, or any buffer under `--headless` —
--- it silently reports "no node" for every position. Asking for the parser
--- and parsing it here makes the answer independent of whether anything
--- else happened to attach first.
---
--- The primary tree only, so this never descends into the injected
--- `markdown_inline` trees; pipes and fences are both outer-grammar.
---@param bufnr integer
---@param row   integer 0-indexed
---@param col   integer 0-indexed
---@return TSNode?
local node_at = function(bufnr, row, col)
    local ok, parser = pcall(
        vim.treesitter.get_parser,
        bufnr,
        "markdown",
        { error = false }
    )
    if not ok or not parser then
        return nil
    end

    local parsed = parser:parse()
    local tree   = parsed and parsed[1]
    if not tree then
        return nil
    end

    return tree:root():named_descendant_for_range(row, col, row, col)
end

--- True if `row` sits inside a fenced or indented code block.
---
--- This is the one judgement the line scanner below cannot make for
--- itself, and the reason Tree-sitter is worth consulting even when it
--- cannot see a table: a pipe table pasted into a ``` fence is not a
--- table, and Tree-sitter knows that.
---@param bufnr integer
---@param row   integer 0-indexed
---@return boolean
M.in_code_block = function(bufnr, row)
    local node = node_at(bufnr, row, 0)
    while node do
        if FENCE_NODES[node:type()] then
            return true
        end
        ---@type TSNode?
        node = node:parent()
    end
    return false
end

--- True if the line could be part of a pipe table: it holds an unescaped
--- pipe and something other than whitespace.
---@param line string
---@return boolean
M.is_table_line = function(line)
    if not line:match("%S") then
        return false
    end
    local i = 1
    while i <= #line do
        local char = line:sub(i, i)
        if char == "\\" then
            i = i + 2
        elseif char == "|" then
            return true
        else
            i = i + 1
        end
    end
    return false
end

--- Extent of the table containing `row`, as 0-indexed inclusive rows.
---
--- Tree-sitter first: it already excludes tables inside code fences, keeps
--- `\|` and `` `a|b` `` as cell content, and handles tables indented in a
--- list or quoted in a blockquote.
---
--- It has two blind spots, both straight from GFM's own rules — a table
--- with no delimiter row yet, and one whose header and delimiter cell
--- counts disagree, are simply not `pipe_table` nodes. Both are states you
--- pass through while editing, which is exactly when you want to format.
--- So fall back to scanning contiguous pipe-bearing lines, gated on
--- `M.in_code_block` so the single case a naive scanner would corrupt
--- stays covered.
---@param bufnr integer
---@param row   integer 0-indexed
---@return integer? start_row 0-indexed, inclusive
---@return integer? end_row   0-indexed, inclusive
M.table_range = function(bufnr, row)
    local node = node_at(bufnr, row, 0)
    while node do
        if node:type() == "pipe_table" then
            local start_row, _, end_row, end_col = node:range()
            -- A node ending at column 0 stops before that row's text.
            if end_col == 0 then
                end_row = end_row - 1
            end
            return start_row, end_row
        end
        node = node:parent()
    end

    if M.in_code_block(bufnr, row) then
        return nil, nil
    end

    local last = vim.api.nvim_buf_line_count(bufnr) - 1
    if row > last then
        return nil, nil
    end

    ---@param at integer
    ---@return string
    local line_at = function(at)
        return vim.api.nvim_buf_get_lines(bufnr, at, at + 1, false)[1] or ""
    end

    if not M.is_table_line(line_at(row)) then
        return nil, nil
    end

    local start_row = row
    while start_row > 0 and M.is_table_line(line_at(start_row - 1)) do
        start_row = start_row - 1
    end
    local end_row = row
    while end_row < last and M.is_table_line(line_at(end_row + 1)) do
        end_row = end_row + 1
    end

    return start_row, end_row
end

--
-- Buffer: rewriting
--

--- A table's own lines, given the inclusive row range `M.table_range`
--- returns.
---@param bufnr     integer
---@param start_row integer 0-indexed, inclusive
---@param end_row   integer 0-indexed, inclusive
---@return string[] lines
local table_lines = function(bufnr, start_row, end_row)
    return vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
end

--- Formats the table containing `row`, leaving the cursor in its own cell.
---
--- Writes nothing when the render matches what is already there. That
--- guard is load-bearing once `M.autocmd` is live: an identical
--- `nvim_buf_set_lines` still sets 'modified' and still pushes an undo
--- state, so without it every keystroke-adjacent trigger would litter the
--- undo tree with no-ops.
---@param bufnr? integer Default: current buffer
---@param row?   integer 0-indexed. Default: the cursor's row
---@return boolean changed
M.format = function(bufnr, row)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    ---@type integer[]?
    local cursor
    if row == nil then
        cursor = vim.api.nvim_win_get_cursor(0)
        row    = cursor[1] - 1
    end

    local start_row, end_row = M.table_range(bufnr, row)
    if not start_row or not end_row then
        return false
    end

    local old = table_lines(bufnr, start_row, end_row)
    local new = M.render(M.parse(old))
    if #new == 0 or vim.deep_equal(old, new) then
        return false
    end

    -- Where the cursor was, in table terms, before the byte columns move
    ---@type integer?
    local column
    ---@type integer?
    local offset
    if cursor and cursor[1] - 1 >= start_row and cursor[1] - 1 <= end_row then
        column, offset = M.cell_at(old[cursor[1] - start_row], cursor[2])
    end

    vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, new)

    if cursor and column and offset then
        -- A render may insert the delimiter row the table was missing, so
        -- clamp rather than assume the row survived in place.
        local at   = math.min(cursor[1] - start_row, #new)
        local line = new[at]
        vim.api.nvim_win_set_cursor(0, {
            start_row + at,
            M.cell_col(line, column, offset),
        })
    end

    return true
end

--- Formats every pipe table in the buffer.
---
--- Back to front, so a table that gains or loses its delimiter row cannot
--- shift the ranges still queued behind it.
---@param bufnr? integer Default: current buffer
---@return integer count Tables actually rewritten
M.format_buffer = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    ---@type integer[]
    local rows = {}
    ---@type integer?
    local previous_end
    local last = vim.api.nvim_buf_line_count(bufnr) - 1
    for row = 0, last do
        if not previous_end or row > previous_end then
            local start_row, end_row = M.table_range(bufnr, row)
            if start_row and end_row then
                rows[#rows + 1] = start_row
                previous_end    = end_row
            end
        end
    end

    ---@type integer
    local count = 0
    for index = #rows, 1, -1 do
        if M.format(bufnr, rows[index]) then
            count = count + 1
        end
    end

    return count
end

--- Sets the alignment of the column under the cursor, then reformats.
---@param align  cgxx.mdtable.Align
---@param bufnr? integer            Default: current buffer
---@return boolean changed
M.set_align = function(align, bufnr)
    bufnr        = bufnr or vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row    = cursor[1] - 1

    local start_row, end_row = M.table_range(bufnr, row)
    if not start_row or not end_row then
        vim.notify("XXMdTable: no table under cursor", vim.log.levels.WARN)
        return false
    end

    local old            = table_lines(bufnr, start_row, end_row)
    local column, offset = M.cell_at(old[row - start_row + 1], cursor[2])

    local tbl = M.parse(old)
    if column > #tbl.align then
        vim.notify("XXMdTable: no column under cursor", vim.log.levels.WARN)
        return false
    end
    tbl.align[column] = align

    local new = M.render(tbl)
    if #new == 0 or vim.deep_equal(old, new) then
        return false
    end

    vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, new)

    local at = math.min(row - start_row + 1, #new)
    vim.api.nvim_win_set_cursor(0, {
        start_row + at,
        M.cell_col(new[at], column, offset),
    })

    return true
end

--
-- Buffer: formatting while editing
--

--- True if this buffer has opted in to reformatting as it is edited.
---
--- Opt-in, not opt-out: reflowing a table under someone who is still
--- typing it is the sort of help nobody asked for, so `M.autocmd` does
--- nothing until `M.enable` or `:XXMdTable toggle` says otherwise.
---@param bufnr integer
---@return boolean
local eligible = function(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end
    if vim.g.cgxx_mdtable == false then
        return false
    end
    return vim.b[bufnr].cgxx_mdtable == true
end

--- Turns on reformat-as-you-edit for a buffer.
---@param bufnr? integer Default: current buffer
---@return nil
M.enable = function(bufnr)
    bufnr                     = bufnr or vim.api.nvim_get_current_buf()
    vim.b[bufnr].cgxx_mdtable = true
    vim.notify("XXMdTable: auto-format enabled", vim.log.levels.INFO)
end

--- Turns off reformat-as-you-edit for a buffer.
---@param bufnr? integer Default: current buffer
---@return nil
M.disable = function(bufnr)
    bufnr                     = bufnr or vim.api.nvim_get_current_buf()
    vim.b[bufnr].cgxx_mdtable = false
    vim.notify("XXMdTable: auto-format disabled", vim.log.levels.INFO)
end

--- Flips reformat-as-you-edit for a buffer.
---@param bufnr? integer Default: current buffer
---@return nil
M.toggle = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if vim.b[bufnr].cgxx_mdtable == true then
        M.disable(bufnr)
    else
        M.enable(bufnr)
    end
end

--- Registers the autocmds that reformat a table as it is edited.
---
--- `InsertLeave` and `TextChanged`, deliberately not `CursorMovedI`:
--- rewriting the line under a moving insert-mode cursor is what makes this
--- class of feature feel possessed. Together with the no-op guard in
--- `M.format` these two give tidy tables without fighting the cursor.
---@return nil
M.autocmd = function()
    vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
        desc     = "Reformat the markdown table under the cursor",
        group    = vim.api.nvim_create_augroup("cgxx.mdtable", {
            clear = true,
        }),
        callback = function(event)
            if not eligible(event.buf) then
                return
            end
            pcall(M.format, event.buf)
        end,
    })
end

--
-- Buffer: keymaps, command
--

--- Buffer-local keymaps, attached per Markdown buffer by
--- `filetype.markdown`'s `setup()`.
---
--- Buffer-local rather than global because they are only meaningful in
--- Markdown, and `lua/filetype/init.lua` dispatches one module per
--- filetype, so `markdown.nex-note` and `markdown.claude` reach this
--- through `filetype.markdown` rather than by being listed here.
---@param bufnr? integer Default: current buffer
---@return nil
M.keymap = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    ---@type { [1]: string, [2]: fun(), [3]: string } []
    local maps = {
        {
            "<leader>tf",
            function()
                M.format(bufnr)
            end,
            "Format markdown table under cursor",
        },
        {
            "<leader>tF",
            function()
                M.format_buffer(bufnr)
            end,
            "Format every markdown table in buffer",
        },
        {
            "<leader>tl",
            function()
                M.set_align("left", bufnr)
            end,
            "Align markdown table column left",
        },
        {
            "<leader>tc",
            function()
                M.set_align("center", bufnr)
            end,
            "Align markdown table column centre",
        },
        {
            "<leader>tr",
            function()
                M.set_align("right", bufnr)
            end,
            "Align markdown table column right",
        },
        {
            "<leader>tn",
            function()
                M.set_align("none", bufnr)
            end,
            "Clear markdown table column alignment",
        },
        {
            "<leader>tt",
            function()
                M.toggle(bufnr)
            end,
            "Toggle markdown table auto-format",
        },
    }

    for _, map in ipairs(maps) do
        vim.keymap.set("n", map[1], map[2], {
            buffer = bufnr,
            desc   = map[3],
            remap  = false,
        })
    end
end

---@type table<string, fun()>
local act_func = {
    format  = function()
        M.format()
    end,
    buffer  = function()
        M.format_buffer()
    end,
    left    = function()
        M.set_align("left")
    end,
    center  = function()
        M.set_align("center")
    end,
    right   = function()
        M.set_align("right")
    end,
    none    = function()
        M.set_align("none")
    end,
    toggle  = function()
        M.toggle()
    end,
    enable  = function()
        M.enable()
    end,
    disable = function()
        M.disable()
    end,
}

--- `nvim_create_user_command` callback backing `XXMdTable`.
---@param opts vim.api.keyset.create_user_command.command_args
---@return nil
M.command = function(opts)
    local act = opts.fargs[1] or "format"
    local fn  = act_func[act]
    if not fn then
        vim.notify("XXMdTable: unknown action " .. act, vim.log.levels.ERROR)
        return
    end
    fn()
end

--- `nvim_create_user_command` completion for `XXMdTable`.
---@return string[] actions
M.complete = function()
    return vim.fn.sort(vim.tbl_keys(act_func))
end

return M
