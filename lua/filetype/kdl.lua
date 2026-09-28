#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

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
    ["kdlNode"]                = { link = "@property" },
}

--- Tree-sitter captures are scoped to `.kdl`, as `filetype.markdown` scopes
--- its own: `nvim_set_hl` is global, so a bare `@type` would recolour every
--- language. `kdlNode` is a syntax group and already KDL's alone.
---@type { [string]: vim.api.keyset.highlight }
M.hlgroup_defs = {}
for hlgroup, defmap in pairs(hlgroup_defs) do
    local scoped           = hlgroup:sub(1, 1) == "@" and hlgroup .. ".kdl"
        or hlgroup
    M.hlgroup_defs[scoped] = defmap
end

return M
