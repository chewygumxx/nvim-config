#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/option/init.lua
--
--

--
-- Setup sibling modules
--

local M = {}

local __this_module = ...

local sibling_modules = {
    "general",
    "fold",
    "view",
}

M.setup = function()
    for _, sibling in ipairs(sibling_modules) do
        _G.setup_guard(__this_module .. "." .. sibling)
    end
end

return M
