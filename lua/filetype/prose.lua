#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/prose.lua
--
--

--
-- Shared settings for prose filetypes with no other overrides
--

local M = {}

local options = {
    spell = true,
}

M.setup = function()
    _G.require_guard("util.option").apply(options, { scope = "local" })
end

return M
