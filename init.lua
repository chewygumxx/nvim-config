#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

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

-- Requires modpath and calls its setup(), if present. A failure in either
-- step is reported via vim.notify rather than propagating, so one broken
-- module can't prevent unrelated modules from loading.
_G.setup_guard = function(modpath)
    local module = _G.require_guard(modpath)
    if not (module and module.setup) then
        return
    end

    local ok, err = pcall(module.setup)
    if not ok then
        vim.notify("Failed to setup() module: " .. modpath .. ": " .. tostring(err), vim.log.levels.ERROR)
    end
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
    _G.setup_guard(modpath)
end
