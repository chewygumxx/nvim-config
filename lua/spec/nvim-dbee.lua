#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

-- 
-- 
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/nvim-dbee.lua
-- 
-- 

local M = {
    "kndndrj/nvim-dbee",
    enabled = false,

    dependencies = {
        "MunifTanjim/nui.nvim",
    },
}

M.build = function()
    -- Install tries to automatically detect the install method.
    -- if it fails, try calling it with one of these parameters:
    --    "curl", "wget", "bitsadmin", "go"
    require("dbee").install()
end

M.config = function()
    require("dbee").setup(--[[optional config]])
end

return M
