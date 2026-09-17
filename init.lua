#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/init.lua
--
--

--
-- Neovim initialisation root
--

-- Wrapper guard for require(modpath).
-- Failure in resolving the module is reported via vim.notify rather than
-- propagating.
---@param modpath string Module filepath
_G.require_guard = function(modpath)
    local ok, module = pcall(require, modpath)
    if not ok then
        vim.notify(
            "Failed to require() module: " .. modpath
                .. "\n" .. tostring(module),
            vim.log.levels.ERROR
        )
        return
    end
    return module
end

-- Wrapper guard for require(modpath).setup().
-- Failure in either resolving the module or calling it's setup() is reported
-- via vim.notify rather than propagating.
---@param modpath string Module filepath
---@param opts    table? Passed to as parameter/arg setup()
---@return nil
_G.setup_guard = function(modpath, opts)
    local module = _G.require_guard(modpath)
    if not (module and module.setup) then
        return
    end

    local ok, err = pcall(module.setup, opts)
    if not ok then
        vim.notify(
            "Failed to setup() module: " .. modpath .. "\n" .. tostring(err),
            vim.log.levels.ERROR
        )
    end
end

_G.setup_guard("cgxx", {
    lsp = {},
    fuzzy = "fzf-lua",
    colorscheme = { "middlenight_blue" },
    lazy = {
        checker = vim.env.HERDR_ENV == nil and vim.env.TERMUX_VERSION == nil,
    },
})

local modules = {
    "option",
    "keymap",
    "filetype", -- After option and keymap for overrides
    "autocmd",
    "usercmd",

    -- After  keymap,     for lazy-load keymap triggers involving vim.g.mapleader
    -- After  filetype,   for lazy-load filetype triggers
    -- After  autocmd,    for augroup dependent plugin spec
    "plugin_manager",

    -- After  plugin_manager,  for treesitter parsing and colorscheme overwrite
    "highlight",
}

for _, module in ipairs(modules) do
    _G.setup_guard(module)
end
