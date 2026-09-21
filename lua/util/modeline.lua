#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/modeline.lua
--
--

--
-- Helper functions for vim modeline resolution
--

local M = {}

--- Explicit nil-check: returns explicit unless it is nil.
---@generic T
---@param explicit T?
---@param fallback T
---@return T
local function n(explicit, fallback)
    if explicit ~= nil then return explicit end
    return fallback
end

---@class util.ModelineOpt
---@field buf?           integer           Fallback source buffer (default: 0)
---@field et?            boolean
---@field expandtab?     boolean           Alias for `et`
---@field sw?            integer | boolean
---@field shiftwidth?    integer | boolean Alias for `sw` (default: buf's own, or 4)
---@field ft?            string | boolean
---@field filetype?      string | boolean  Alias for `ft` (default: buf's own filetype)
---@field append?        string            Extra `:set` clause(s), appended verbatim
---@field commentstring? string            printf-style wrapper (default: buf's own)

--- Builds a `vim:set ...:` modeline comment from opt, falling back to
--- buf's own option values for anything left unset.
---@param opt? util.ModelineOpt
---@return string modeline
M.base = function(opt)
    opt       = opt or {}
    local buf = opt.buf or 0
    -- The following three options may be set false for elision
    local et = n(opt.et, n(opt.expandtab, vim.bo[buf].expandtab))
    local sw = n(
        opt.sw,
        n(opt.shiftwidth, n(vim.bo[buf].shiftwidth, 4))
    )
    local ft = n(opt.ft, n(opt.filetype, vim.bo[buf].filetype))
    -- For additional :set options not provided for
    local append        = opt.append
    local commentstring = opt.commentstring or (vim.bo[buf].commentstring ~= ""
            and vim.bo[buf].commentstring) or "%s"

    local modeline = "vim:set"
    modeline       = modeline .. (et and " expandtab" or "")
    modeline       = modeline .. (sw and " shiftwidth=" .. tostring(sw) or "")
    modeline       = modeline .. (ft and ft ~= "" and " filetype=" .. ft or "")
    modeline       = modeline .. (append or "")

    modeline = modeline .. ":"

    return string.format(commentstring, modeline)
end

return M
