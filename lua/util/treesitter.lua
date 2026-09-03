#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/util/treesitter.lua
--
--

--
-- Custom treesitter query predicates
--

local M = {}

-- #adjacent? @a @b ...
local cached_source, cached_lines

local function range_text(source, row, start_col, end_col)
    if type(source) == "number" then
        return vim.api.nvim_buf_get_text(source, row, start_col, row, end_col, {})[1] or ""
    end
    if cached_source ~= source then
        cached_source, cached_lines = source, vim.split(source, "\n", { plain = true })
    end
    local line = cached_lines[row + 1] or ""
    return line:sub(start_col + 1, end_col)
end

-- True if two nodes are separated by nothing but whitespace (usually
-- nothing at all: true byte adjacency), on the same line.
local function whitespace_only_gap(source, a, b)
    local _, _, a_end_row, a_end_col = a:range()
    local b_row, b_col = b:range()
    if a_end_row ~= b_row then
        return false
    end
    return not range_text(source, a_end_row, a_end_col, b_col):match("%S")
end

M.adjacent = function(match, _, source, predicate)
    local nodes = {}
    for i = 2, #predicate do
        local list = match[predicate[i]]
        if list then
            vim.list_extend(nodes, list)
        end
    end
    if #nodes < 2 then
        return true
    end

    table.sort(nodes, function(a, b)
        local a_row, a_col = a:range()
        local b_row, b_col = b:range()
        return a_row < b_row or (a_row == b_row and a_col < b_col)
    end)

    for i = 1, #nodes - 1 do
        if not whitespace_only_gap(source, nodes[i], nodes[i + 1]) then
            return false
        end
    end

    return true
end

-- #last-matching? @a "pattern"
M.last_matching = function(match, _, source, predicate)
    local nodes = match[predicate[2]]
    local pattern = predicate[3]
    if not nodes then
        return true
    end

    for _, node in ipairs(nodes) do
        local sibling = node:next_sibling()
        while sibling do
            if vim.treesitter.get_node_text(sibling, source):match(pattern) then
                return false
            end
            sibling = sibling:next_sibling()
        end
    end

    return true
end

-- #header-line? @capture
local function maximal_adjacent_run(node, source)
    local first, last = node, node

    local prev = first:prev_sibling()
    while prev and whitespace_only_gap(source, prev, first) do
        first, prev = prev, prev:prev_sibling()
    end

    local nxt = last:next_sibling()
    while nxt and whitespace_only_gap(source, last, nxt) do
        last, nxt = nxt, nxt:next_sibling()
    end

    local first_row, first_col             = first:range()
    local _, _, last_end_row, last_end_col = last:range()
    if first_row ~= last_end_row then
        return nil
    end
    return range_text(source, first_row, first_col, last_end_col)
end

local HEADER_LINE_PATTERNS = {
    { shape = "repo", pattern = "%s*~[%w_-]+/[%w_-]+%.git$" },  -- ~owner/name.git
    { shape = "path", pattern = "%s*:::%s*:/[%w_/.-]+$"     },  -- ::: :/path/to/file
}

-- #header-line? @capture ["repo"|"path"]
M.header_line = function(match, _, source, predicate)
    local nodes = match[predicate[2]]
    if not nodes then
        return true
    end
    local want_shape = predicate[3]

    for _, node in ipairs(nodes) do
        local line = maximal_adjacent_run(node, source)
        if not line then
            return false
        end

        local matched = false
        for _, entry in ipairs(HEADER_LINE_PATTERNS) do
            if (not want_shape or entry.shape == want_shape) and line:match(entry.pattern) then
                matched = true
                break
            end
        end
        if not matched then
            return false
        end
    end

    return true
end

M.setup = function()
    vim.treesitter.query.add_predicate("adjacent?",      M.adjacent,      { force = true })
    vim.treesitter.query.add_predicate("last-matching?", M.last_matching, { force = true })
    vim.treesitter.query.add_predicate("header-line?",   M.header_line,   { force = true })
end

return M
