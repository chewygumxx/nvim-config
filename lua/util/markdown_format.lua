#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/markdown_format.lua
--
--

--
-- 'formatexpr' for Markdown: `gq`, `gw` and auto-wrap, minus the blocks
-- that are not prose.
--
-- Vim's internal formatter knows nothing of Markdown. Asked to `gqG` over
-- a document, it joins a fenced code block into one paragraph, folds the
-- YAML frontmatter into a single unparseable line and flattens a pipe
-- table. So the range is split around those blocks and each prose run
-- between them is handed to the internal formatter on its own.
--
-- The hanging indent under a list item (two columns under `- `, six under
-- `- [ ] `) is not done here: it is 'formatlistpat' with `n` in
-- 'formatoptions', set by `filetype.markdown`, and the internal formatter
-- applies it to every run this module passes on.
--

local M = {}

--- Block nodes the formatter must leave exactly as written, in the outer
--- `markdown` grammar.
---@type string
local protected_query = [[
[
  (fenced_code_block)
  (indented_code_block)
  (minus_metadata)
  (plus_metadata)
  (html_block)
  (pipe_table)
] @protected
]]

---@class (exact) cgxx.markdown_format.Range
---@field first integer 1-indexed, inclusive
---@field last  integer 1-indexed, inclusive

--- The protected blocks as found by a line scan, for a buffer Tree-sitter
--- cannot parse: frontmatter on line 1, and backtick or tilde fences. The
--- weaker answer, but a better one than formatting a fence's contents.
---@param bufnr integer
---@return cgxx.markdown_format.Range[] ranges
local scan = function(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    ---@type cgxx.markdown_format.Range[]
    local ranges = {}

    local index = 1
    if lines[1] == "---" then
        for lnum = 2, #lines do
            if lines[lnum] == "---" or lines[lnum] == "..." then
                ranges[#ranges + 1] = { first = 1, last = lnum }
                index               = lnum + 1
                break
            end
        end
    end

    ---@type string?
    local fence
    ---@type integer
    local opened = 0
    for lnum = index, #lines do
        local marker = lines[lnum]:match("^%s*(```+)")
            or lines[lnum]:match("^%s*(~~~+)")
        if fence == nil and marker then
            fence, opened = marker, lnum
        elseif fence and marker
            and marker:sub(1, 1) == fence:sub(1, 1) and #marker >= #fence then
            ranges[#ranges + 1] = { first = opened, last = lnum }
            fence               = nil
        end
    end
    -- An unclosed fence runs to the end of the document, as CommonMark has it
    if fence then
        ranges[#ranges + 1] = { first = opened, last = #lines }
    end

    return ranges
end

--- Every block in bufnr that is not prose, as 1-indexed line ranges.
---
--- Parses the buffer itself rather than trusting an existing tree, for the
--- reason `util.markdown_table` gives: nothing may have parsed it yet.
---@param bufnr? integer (default: current buffer)
---@return cgxx.markdown_format.Range[] ranges
M.protected = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local ok, parser = pcall(
        vim.treesitter.get_parser,
        bufnr,
        "markdown",
        { error = false }
    )
    if not ok or not parser then
        return scan(bufnr)
    end
    local parsed = parser:parse()
    local tree   = parsed and parsed[1]
    if not tree then
        return scan(bufnr)
    end

    local query = vim.treesitter.query.parse("markdown", protected_query)
    ---@type cgxx.markdown_format.Range[]
    local ranges = {}
    for _, node in query:iter_captures(tree:root(), bufnr) do
        local start_row, _, end_row, end_col = node:range()
        -- A block node ends at column 0 of the line after its last one
        if end_col == 0 and end_row > start_row then
            end_row = end_row - 1
        end
        ranges[#ranges + 1] = { first = start_row + 1, last = end_row + 1 }
    end
    return ranges
end

--- Whether line lnum falls inside one of ranges.
---@param ranges cgxx.markdown_format.Range[]
---@param lnum   integer                      1-indexed
---@return boolean
local within = function(ranges, lnum)
    for _, range in ipairs(ranges) do
        if lnum >= range.first and lnum <= range.last then
            return true
        end
    end
    return false
end

--- Splits first..last into the runs of lines outside every range.
---@param ranges cgxx.markdown_format.Range[]
---@param first  integer                      1-indexed
---@param last   integer                      1-indexed, inclusive
---@return cgxx.markdown_format.Range[] runs In buffer order
M.runs = function(ranges, first, last)
    ---@type cgxx.markdown_format.Range[]
    local runs = {}
    ---@type integer?
    local opened
    for lnum = first, last do
        if within(ranges, lnum) then
            if opened then
                runs[#runs + 1] = { first = opened, last = lnum - 1 }
                opened          = nil
            end
        elseif opened == nil then
            opened = lnum
        end
    end
    if opened then
        runs[#runs + 1] = { first = opened, last = last }
    end
    return runs
end

--- Runs the internal formatter over first..last of the current buffer.
---
--- 'formatexpr' is emptied for the duration, since `gq` would otherwise
--- call straight back into this module, and is restored even if the
--- format raises.
---@param first integer 1-indexed
---@param last  integer 1-indexed, inclusive
---@return nil
local internal = function(first, last)
    local saved       = vim.bo.formatexpr
    vim.bo.formatexpr = ""
    local ok, err     = pcall(
        vim.api.nvim_command,
        ("keepjumps normal! %dGgq%dG"):format(first, last)
    )
    vim.bo.formatexpr = saved
    if not ok then
        error(err, 0)
    end
end

--- The 'formatexpr' itself, ie. `v:lua.require'util.markdown_format'
--- .formatexpr()`.
---
--- In insert mode Vim calls this to auto-wrap the line being typed, with
--- `v:char` set: returning 1 hands that back to the internal formatter,
--- and returning 0 on a protected line is what stops a long line of code
--- in a fence wrapping as it is typed.
---@return integer handled 0 when done here, 1 to defer to Vim
M.formatexpr = function()
    local first  = vim.v.lnum
    local last   = first + vim.v.count - 1
    local ranges = M.protected()

    if vim.v.char ~= "" then
        return within(ranges, first) and 0 or 1
    end

    local runs = M.runs(ranges, first, last)
    if #runs == 0 then
        return 0
    end

    -- Bottom-up, so formatting a run never moves the line numbers of the
    -- runs above it. The cursor ends where `gq` leaves it, on the last
    -- formatted line, which the runs above shift by their change in length.
    internal(runs[#runs].first, runs[#runs].last)
    local cursor = vim.fn.line(".")
    for index = #runs - 1, 1, -1 do
        local before = vim.api.nvim_buf_line_count(0)
        internal(runs[index].first, runs[index].last)
        cursor = cursor + vim.api.nvim_buf_line_count(0) - before
    end
    vim.api.nvim_win_set_cursor(0, { cursor, 0 })

    return 0
end

return M
