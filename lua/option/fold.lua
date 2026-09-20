#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/option/fold.lua
--
--

--
-- Neovim fold mannerism
--

local M = {}

--- `foldtext` callback (`v:lua.cgxx_foldtext()`): renders the folded
--- line's own text, indent-collapsed into "~", followed by a right-aligned
--- "[N lines] [lvl=N]" summary. Reads fold state from `vim.v.fold*`.
---@return string text
local foldtext = function()
    -- Buffer
    local tabstop = vim.api.nvim_get_option_value("tabstop", {})
    if tabstop   == 0 then tabstop   = 4  end
    local textwidth = vim.api.nvim_get_option_value("textwidth", {})
    if textwidth == 0 then textwidth = 80 end

    -- Metadata
    local start = vim.v.foldstart           -- Line number of fold beginning
    local count = vim.v.foldend - start + 1 -- Fold size in lines
    local level = vim.v.foldlevel           -- Degree of fold nesting

    -- Label
    local label      = vim.fn.getline(start)
        :gsub("\t", string.rep(" ", tabstop))
    local indent_pos = label:find("%S")
    local indent     = indent_pos and (indent_pos - 1) or 0

    if indent >= 4 then
        label = label:gsub(
            "^" .. string.rep(" ", indent),
            string.rep(" ", indent - 4) .. "~~~ "
        )
    elseif indent == 2 then
        label = label:gsub("^  ", "~ ")
    elseif indent == 1 then
        label = label:gsub("^ ", "~")
    elseif indent == 3 then
        label = label:gsub("^   ", "~~ ")
    end

    -- Info
    local fold_info = string.format("[%d lines] [lvl=%i]", count, level)
    local alignment = string.rep(" ", textwidth - #label - #fold_info - 1)

    return label .. alignment .. fold_info
end

--- Registers `foldtext` as a global and applies this module's fold
--- option values.
---@return nil
M.setup = function()
    _G.cgxx_foldtext = foldtext
    vim.opt.foldtext = "v:lua.cgxx_foldtext()"

    vim.o.foldmethod = "expr"
    vim.o.foldlevel  = 2
    vim.o.fillchars  = "fold: "
end

return M
