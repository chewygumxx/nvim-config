#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/filetype/kdl.lua
--
--

--
-- KDL filetype settings
--

local M = {}

local options = {
}

local hlgroup_defs = {
    ["@type"]                  = { link = "@property" },
    ["@punctuation.bracket"]   = { link = "PreProc"   },
    ["@punctuation.delimiter"] = { link = "Macro"     },
}

-- Highlight links are session-global; only need to be defined once.
for hlgroup, defmap in pairs(hlgroup_defs) do
    vim.api.nvim_set_hl(0, hlgroup .. ".kdl", defmap)
end

M.setup = function()
    _G.require_guard("util.option").apply(options, { scope = "local" })
end

return M
