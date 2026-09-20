#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/option.lua
--
--

--
-- Apply a table of option values with a shared scope
--

local M = {}

--- Applies a table of option name/value pairs with a shared scope.
---@param options     table<string, any>    Map of option name to value
---@param scope_opts? vim.api.keyset.option Passed to `nvim_set_option_value`
---@return nil
M.apply = function(options, scope_opts)
    for opt, value in pairs(options) do
        vim.api.nvim_set_option_value(opt, value, scope_opts or {})
    end
end

return M
