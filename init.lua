#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/init.lua
--
--

--
-- Neovim initialisation root
--


_G.require_guard = function(modpath)
    local ok, module = pcall(require, modpath)
    if not ok then
        vim.notify("Failed to require() module: " .. modpath, vim.log.levels.ERROR)
        return
    end
    return module
end

-- Initialisation Order
local modules = {
    "option",    -- Should be overwritten by filetype, and includes essential opts
    "keymap",    -- Should be overwritten by filetype

    "filetype",

    "autocmd",
    "usercmd",

    -- Plugin lazy-load management
    -- After  keymap,     for lazy-load keymap triggers involving vim.g.mapleader
    -- After  filetype,   for lazy-load filetype triggers
    -- After  autocmd,    for augroup dependent plugin spec
    -- Before highlight,  for treesitter parsing and colorscheme overwrite
    "plugin_manager",

    "highlight"
}

for _, modpath in ipairs(modules) do
    local module = _G.require_guard(modpath)
    if module then
        module.setup()
    end
end
