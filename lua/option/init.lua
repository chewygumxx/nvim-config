#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/option/init.lua
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

--- Sets up each sibling option module.
---@return nil
M.setup = function()
    for _, sibling in ipairs(sibling_modules) do
        _G.setup_guard(__this_module .. "." .. sibling)
    end
end

return M
