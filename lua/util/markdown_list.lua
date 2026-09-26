#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/markdown_list.lua
--
--

--
-- Continues a Markdown list onto the next line: a new `- `, `- [ ] `, `2. `
-- or `> `, at the indent the current item sits at.
--
-- Neovim does not do this, and not by omission. `$VIMRUNTIME/ftplugin/
-- markdown.vim` sets `formatoptions-=r formatoptions-=o`, ie. it removes
-- the two flags that continue a comment leader on `<CR>` and on `o`/`O`.
-- Restoring them would not be enough either: the leaders it does define are
-- `comments=fb:*,fb:-,fb:+,n:>`, and the `f` flag means "only the first
-- line carries the leader", so `o` yields a bare indent rather than a new
-- bullet. That is the whole symptom, ie. a newline that indents but does
-- not continue, and sometimes does not indent correctly either.
--
-- `comments` could not express what is wanted regardless. It has no way to
-- repeat `- [ ] ` rather than `- `, and no way to turn `1.` into `2.`, so
-- the continuation is computed here instead.
--
-- Deliberately not bound to `<CR>`. `lua/spec/blink.cmp.lua` maps `<CR>` to
-- `{ "accept", "fallback" }`, and a buffer-local mapping outranks a global
-- one, so taking `<CR>` here would stop completion being acceptable with
-- Enter in exactly the filetype where link and word completion is used
-- most. `o`/`O` are the Vim answer to "new line below/above", and
-- `<M-CR>` covers the same thing without leaving insert mode.
--

local M = {}

--- One parsed Markdown list item.
---@class cgxx.markdown_list.Item
---@field indent   string                         Leading whitespace, reproduced verbatim
---@field marker   string                         The marker as written, eg. `-`, `1`, `>`
---@field delim    string                         `.` or `)` for an ordered item, otherwise ""
---@field spacing  string                         Whitespace between the marker and the content
---@field kind     "bullet" | "ordered" | "quote"
---@field checkbox string?                        `" "`, `"x"` or `"X"` when the item has one
---@field content  string                         Everything after the marker and any checkbox

--- The patterns an item line is recognised by, most specific first: a
--- checkbox item is also a bullet item, so the checkbox forms have to be
--- tried before the plain ones or the `[ ]` would be read as content.
---
--- Each entry names the captures its pattern yields, in order, so that one
--- loop can build the item rather than a branch per pattern.
---@type { pattern: string, kind: "bullet" | "ordered" | "quote", captures: string[] } []
local forms = {
    {
        pattern = "^(%s*)([-*+])(%s+)%[([ xX])%]%s(.*)$",
        kind = "bullet",
        captures = { "indent", "marker", "spacing", "checkbox", "content" },
    },
    {
        pattern = "^(%s*)(%d+)([.)])(%s+)%[([ xX])%]%s(.*)$",
        kind = "ordered",
        captures = {
            "indent",
            "marker",
            "delim",
            "spacing",
            "checkbox",
            "content",
        },
    },
    {
        pattern = "^(%s*)(%d+)([.)])(%s+)(.*)$",
        kind = "ordered",
        captures = { "indent", "marker", "delim", "spacing", "content" },
    },
    {
        pattern = "^(%s*)([-*+])(%s+)(.*)$",
        kind = "bullet",
        captures = { "indent", "marker", "spacing", "content" },
    },
    -- `>` needs no space after it to be a blockquote, so `spacing` may be
    -- empty here where it cannot be for the forms above
    {
        pattern = "^(%s*)(>+)(%s*)(.*)$",
        kind = "quote",
        captures = { "indent", "marker", "spacing", "content" },
    },
}

--- Parses one line as a Markdown list item, or returns nil if it is not
--- one.
---@param line string
---@return cgxx.markdown_list.Item? item
M.parse = function(line)
    for _, form in ipairs(forms) do
        ---@type string[]
        local matched = { line:match(form.pattern) }
        if matched[1] ~= nil then
            ---@type cgxx.markdown_list.Item
            local item = {
                indent = "",
                marker = "",
                delim = "",
                spacing = " ",
                kind = form.kind,
                content = "",
            }
            for index, field in ipairs(form.captures) do
                item[field] = matched[index]
            end
            return item
        end
    end
    return nil
end

--- The prefix a new sibling of item begins with.
---
--- An ordered item advances its number; nothing renumbers the rest of the
--- list, deliberately, since Markdown renderers do not care and rewriting
--- lines the user did not touch is worse than a list that counts `1. 2. 4.`.
--- A checkbox item always continues unchecked, whatever its own state.
---@param item    cgxx.markdown_list.Item
---@param advance boolean?                Increment an ordered marker; true when omitted
---@return string prefix
M.sibling = function(item, advance)
    local marker = item.marker
    if item.kind == "ordered" and advance ~= false then
        marker = tostring((tonumber(item.marker) or 0) + 1)
    end

    local prefix = item.indent .. marker .. item.delim .. item.spacing
    if item.checkbox ~= nil then
        prefix = prefix .. "[ ] "
    end
    return prefix
end

--- Whether item has no content of its own, ie. it is a marker and nothing
--- else. Continuing one of those is how an endless list of empty bullets
--- gets written, so the callers below end the list instead.
---@param item cgxx.markdown_list.Item
---@return boolean empty
M.empty = function(item)
    return item.content:match("^%s*$") ~= nil
end

--- Opens a new line below or above the cursor, continuing the list if the
--- cursor is on an item, and leaves the buffer in insert mode at the end of
--- the new line.
---
--- Returns false when the cursor is not on a list item, which is the
--- caller's cue to let `o`/`O` do their ordinary thing rather than this
--- module reimplementing them.
---@param below boolean
---@param bufnr integer?
---@return boolean continued
M.open = function(below, bufnr)
    local buf      = bufnr or vim.api.nvim_get_current_buf()
    local position = vim.api.nvim_win_get_cursor(0)
    local row      = position[1]
    local line     = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
        or ""

    local item = M.parse(line)
    if item == nil then
        return false
    end

    if M.empty(item) then
        -- Ending the list: the marker the cursor sits on is removed rather
        -- than a second empty one being added below it
        vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { "" })
        vim.api.nvim_win_set_cursor(0, { row, 0 })
        vim.cmd("startinsert!")
        return true
    end

    -- Opening above reuses the marker as written: advancing it would leave
    -- the line below carrying the same number
    local prefix = M.sibling(item, below)
    local at     = below and row or row - 1
    vim.api.nvim_buf_set_lines(buf, at, at, false, { prefix })
    vim.api.nvim_win_set_cursor(0, { at + 1, #prefix })
    vim.cmd("startinsert!")
    return true
end

--- Splits the current line at the cursor and continues the list on the new
--- line, carrying any text that was to the right of the cursor with it.
---
--- The insert-mode counterpart of `M.open`. Returns false when the cursor
--- is not on a list item.
---@param bufnr integer?
---@return boolean continued
M.split = function(bufnr)
    local buf         = bufnr or vim.api.nvim_get_current_buf()
    local position    = vim.api.nvim_win_get_cursor(0)
    local row, column = position[1], position[2]
    local line        = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
        or ""

    local item = M.parse(line)
    if item == nil then
        return false
    end

    if M.empty(item) then
        vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { "", "" })
        vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
        return true
    end

    local prefix = M.sibling(item)
    local before = line:sub(1, column)
    local after  = line:sub(column + 1)
    vim.api.nvim_buf_set_lines(
        buf,
        row - 1,
        row,
        false,
        { before, prefix .. after }
    )
    vim.api.nvim_win_set_cursor(0, { row + 1, #prefix })
    return true
end

--- The buffer-local mappings, attached per Markdown buffer by
--- `filetype.markdown.setup` and by the compound Markdown filetypes.
---
--- `o`/`O` fall back by feeding themselves with remapping off, so a line
--- that is not a list item behaves exactly as it would unmapped rather than
--- through an approximation of it.
---@param bufnr integer
---@return nil
M.keymap = function(bufnr)
    ---@type { mode: string, lhs: string, desc: string, action: fun(): nil } []
    local maps = {
        {
            mode = "n",
            lhs = "o",
            desc = "Open a new list item below",
            action = function()
                if not M.open(true, bufnr) then
                    vim.api.nvim_feedkeys("o", "n", false)
                end
            end,
        },
        {
            mode = "n",
            lhs = "O",
            desc = "Open a new list item above",
            action = function()
                if not M.open(false, bufnr) then
                    vim.api.nvim_feedkeys("O", "n", false)
                end
            end,
        },
        {
            mode = "i",
            lhs = "<M-CR>",
            desc = "Continue the list on a new line",
            action = function()
                if not M.split(bufnr) then
                    vim.api.nvim_feedkeys(
                        vim.keycode("<CR>"),
                        "n",
                        false
                    )
                end
            end,
        },
    }

    for _, map in ipairs(maps) do
        vim.keymap.set(map.mode, map.lhs, map.action, {
            buffer = bufnr,
            desc = map.desc,
            silent = true,
        })
    end
end

return M
