#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/help.lua
--
--

--
-- Filetype-specific configuration for Neovim help
--

local M = {}

--- Don't export, exclusively intended for M.setup
---@type { [string]: number | string | boolean }
local local_opts = {
    relativenumber = false,
    number = true,
}

--- Implements filetype-specific configuration for Neovim help
--- - Buffer opened via `:edit` rather than `:help`
--- - It is the only window
---@param opts vim.api.keyset.create_autocmd.callback_args
---@return nil
M.setup = function(opts)
    -- Buffer opened via `:edit` rather than `:help`
    if vim.bo[opts.buf].buftype ~= "help" then
        return
    end

    -- Only one window
    if vim.fn.winlayout()[1] == "leaf" then
        return
    end

    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_config(win, { split = "right", win = win })
    vim.api.nvim_win_set_width(win, 90)
    local set_local = vim.opt_local --[[@as table<string, boolean | number | string>]]
    for opt, val in pairs(local_opts) do
        set_local[opt] = val
    end
end

return M
