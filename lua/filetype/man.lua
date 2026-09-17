#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/home/dot_config/nvim/lua/filetype/man.lua
--
--

--
-- Filetype-specific configuration for manpages
--

local M = {}

local options = {
    number = true,
}

M.setup = function()
    _G.require_guard("util.option").apply(options, { scope = "local" })
end

return M
