#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/init.lua
--
--

--
-- Neovim initialisation root
--

--- ****************
--- Essential Guard
--- ****************

-- Wrapper guard for require(modpath).
-- Failure in resolving the module is reported via vim.notify rather than
-- propagating.
---@param modpath string Module filepath
---@return unknown? module nil if require() failed
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

--- **********************
--- Module Initialisation
--- **********************

local modules = {
    "option",
    "keymap",
    "filetype", -- After option and keymap for overrides
    "autocmd",
    "usercmd",
}

for _, module in ipairs(modules) do
    _G.setup_guard(module)
end

-- After  keymap,   for lazy-load keymap triggers involving vim.g.mapleader
-- After  filetype, for lazy-load filetype triggers
-- After  autocmd,  for augroup dependent plugin spec
_G.setup_guard("util.lazy", {
    git  = { url_format = "git@github.com:%s.git" },
    spec = require("util.spec"),
})

-- After  util.lazy,  for treesitter parsing and colorscheme overwrite
_G.setup_guard("highlight")
