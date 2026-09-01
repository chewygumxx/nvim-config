#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/dot_config/nvim/lua/option/init.lua
--
--

--
-- Setup sibling modules
--

local M = {}

local __this_module = ...

local declarative = function()
    local sibling_modules = {
        "general",
        "fold",
        "view",
    }
    for _, sibling in ipairs(sibling_modules) do
        require(__this_module .. "." .. sibling).setup()
    end
end

local aggregate = function()
    local path = package.searchpath(__this_module, package.path)
    local dirname = vim.fs.dirname(path)
    for name, type in vim.fs.dir(dirname) do
        if type == "file" and name ~= "init.lua" and name:sub(-4) == ".lua" then
            local sibling = name:sub(1, -5)
            require(__this_module .. "." .. sibling).setup()
        end
    end
end

M.setup = function()
    declarative()
    --aggregate()
end

return M
