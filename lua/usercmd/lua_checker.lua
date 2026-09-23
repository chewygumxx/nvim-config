#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/usercmd/lua_checker.lua
--
--

--
-- Backs the XXLuaChecker user command
--

local M = {}

--- `XXLuaChecker` callback: sets the active lua type checker to
--- opts.fargs[1], or toggles to the next one if called bare.
---@param opts vim.api.keyset.create_user_command.command_args
---@return nil
M.command = function(opts)
    local lua_checker = require("util.lua_checker")
    if opts.fargs[1] then
        lua_checker.set(opts.fargs[1])
    else
        lua_checker.toggle()
    end
end

--- Completion candidates for `XXLuaChecker`'s single argument.
---@return string[]
M.complete = function()
    return require("util.lua_checker").checkers
end

return M
