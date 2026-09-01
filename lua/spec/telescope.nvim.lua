#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

-- 
-- 
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/telescope.nvim.lua
-- 
-- 

local M = {
    "nvim-telescope/telescope.nvim",
    enabled = false,
    version = "*",

    dependencies = {
        "nvim-lua/plenary.nvim",
        -- optional but recommended
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    }
} 

return M
