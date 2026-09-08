#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/filetype/dosini.lua
--
--

--
-- dosini filetype settings
--

local M = {}

local options = {
    commentstring = "# %s"
}

M.setup = function()
    _G.require_guard("util.option").apply(options, { scope = "local" })
end

return M
