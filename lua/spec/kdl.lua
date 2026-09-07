#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/kdl.lua
--
--


---@module "lazy"
---@type LazySpec
local M = {
    "imsnif/kdl.vim",
    ft = { 'kdl' }
}

return M
