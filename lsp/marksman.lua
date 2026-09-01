#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

-- 
-- 
-- ~chewygumxx/dotfiles.git
-- ::: :/dot_config/nvim/lsp/marksman.lua
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
