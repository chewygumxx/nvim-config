#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/util/text.lua
--
--

--
-- Helper functions for text manipulation
--

local M = {}

M.wrap_comment = function(text, width, opt)
    local width  = width or vim.o.textwidth ~= 0 and vim.o.textwidth or 80
    local opt    = opt or {}
    local buffer = opt.buffer or 0
    local commentstring = opt.commentstring
        or (vim.bo[buffer].commentstring ~= "" and vim.bo[buffer].commentstring)
        or "%s"

    local lines   = {} 
    local current = ""
    for word in text:gmatch("%S+") do
        local candidate = current == "" and word or current .. " " .. word
        if #candidate > (width - (#commentstring - 2)) then
            lines[#lines + 1] = string.format(commentstring, current)
            current = word
        else
            current = candidate
        end
    end
    
    -- If commentstring has a suffix after %s (<!-- block style comment -->)
    if not commentstring:match("%%s$") then
        -- Append right-side padding
        local pad = width - #current - (#commentstring - 2)
        current = current .. string.rep(" ", pad)
    end

    lines[#lines + 1] = string.format(commentstring, current)

    return lines
end

return M
