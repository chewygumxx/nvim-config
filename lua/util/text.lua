#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/text.lua
--
--

--
-- Helper functions for text manipulation
--

local M = {}

---@class util.WrapCommentOpt
---@field buffer?        integer Source of the fallback `commentstring` (default: 0)
---@field commentstring? string  printf-style wrapper (default: buffer's own)

--- Wraps text into a list of comment lines no wider than width, each
--- formatted through commentstring.
---@param text   string
---@param width? integer             Default: 'textwidth', or 80 if unset
---@param opt?   util.WrapCommentOpt
---@return string[] lines
M.wrap_comment = function(text, width, opt)
    width               = width or vim.o.textwidth ~= 0 and vim.o.textwidth
        or 80
    opt                 = opt or {}
    local buffer        = opt.buffer or 0
    local commentstring = opt.commentstring
        or (vim.bo[buffer].commentstring ~= "" and vim.bo[buffer].commentstring)
        or "%s"

    ---@type string[]
    local lines = {}
    ---@type string
    local current = ""
    for word in text:gmatch("%S+") do
        local candidate = current == "" and word or current .. " " .. word
        if #candidate > (width - (#commentstring - 2)) then
            if current ~= "" then
                lines[#lines + 1] = string.format(commentstring, current)
            end
            current = word
        else
            ---@type string
            current = candidate
        end
    end

    -- If commentstring has a suffix after %s (<!-- block style comment -->)
    if not commentstring:match("%%s$") then
        -- Append right-side padding
        local pad = width - #current - (#commentstring - 2)
        current   = current .. string.rep(" ", pad)
    end

    lines[#lines + 1] = string.format(commentstring, current)

    return lines
end

return M
