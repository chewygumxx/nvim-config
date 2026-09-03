#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

-- 
-- 
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/render-markdown.nvim.lua
-- 
-- 

-- 
-- 
-- 

local M = {
    'MeanderingProgrammer/render-markdown.nvim',
    enabled = false,

    ft = { "markdown" },
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'nvim-tree/nvim-web-devicons'
    },
    opts = {},
}

return M
