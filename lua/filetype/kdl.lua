#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/kdl.lua
--
--

--
-- KDL filetype settings
--

local M = {}

---@type { [string]: vim.api.keyset.highlight }
local hlgroup_defs = {
    ["@type"]                  = { link = "@property" },
    ["@punctuation.bracket"]   = { link = "PreProc" },
    ["@punctuation.delimiter"] = { link = "Macro" },
}

---@type { [string]: vim.api.keyset.highlight }
M.hlgroup_defs = {}
for hlgroup, defmap in pairs(hlgroup_defs) do
    M.hlgroup_defs[hlgroup .. ".kdl"] = defmap
end

return M
