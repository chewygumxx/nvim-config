#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/util/modeline.lua
--
--

--
-- Helper functions for vim modeline resolution
--

local M = {}

-- Explicit nil-check
local function n(explicit, fallback)
    if explicit ~= nil then return explicit end
    return fallback
end

M.base = function(opt)
    local opt = opt or {}
    local buf = opt.buf or 0
    -- The following three options may be set false for elision
    local et  = n(opt.et, n(opt.expandtab,    vim.bo[buf].expandtab))
    local sw  = n(opt.sw, n(opt.shiftwidth, n(vim.bo[buf].shiftwidth, 4)))
    local ft  = n(opt.ft, n(opt.filetype,     vim.bo[buf].filetype))
    local append = opt.append -- For additional :set options not provided for
    local commentstring = opt.commentstring
        or (vim.bo[buf].commentstring ~= "" and vim.bo[buf].commentstring)
        or "%s"

    local modeline = "vim:set"
    modeline = modeline .. (et and " expandtab" or "")
    modeline = modeline .. (sw and " shiftwidth=" .. tostring(sw) or "")
    modeline = modeline .. (ft and ft ~= "" and " filetype=" .. ft or "")
    modeline = modeline .. (append or "")

    modeline = modeline .. ":"

    return string.format(commentstring, modeline)
end

return M
