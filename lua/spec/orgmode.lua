#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

-- 
-- 
-- ~chewygumxx/dotfiles.git
-- ::: :/dot_config/nvim/lua/spec/orgmode.lua
-- 
-- 

-- 
-- I don't think I've ever used this
-- 

local M = {
    'nvim-orgmode/orgmode',
    
    ft = { 'org' },
    opts = {
        org_agenda_files = '~/nexus/orgmode/**/*',
        org_default_notes_file = '~/nexus/orgmode/refile.org',
    },
}

return M
