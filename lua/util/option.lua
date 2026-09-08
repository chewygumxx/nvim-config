#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/util/option.lua
--
--

--
-- Apply a table of option values with a shared scope
--

local M = {}

M.apply = function(options, scope_opts)
    for opt, value in pairs(options) do
        vim.api.nvim_set_option_value(opt, value, scope_opts or {})
    end
end

return M
