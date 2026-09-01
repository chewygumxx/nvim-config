#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

-- 
-- 
-- ~chewygumxx/dotfiles.git
-- ::: :/dot_config/nvim/lua/spec/lazydev.nvim.lua
-- 
-- 

-- 
-- 
-- 

local M = {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
        library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
    },
}

return M
