#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

-- 
-- 
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lsp/marksman.lua
-- 
-- 

-- 
-- 
-- 


local M = {
    cmd          = { "marksman", "server" },
    filetypes    = { "markdown" },
    root_markers = { ".marksman.toml", ".git" },
}

return M
