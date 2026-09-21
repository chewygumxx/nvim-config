#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/help.lua
--
--

local M = {}

--- Widens the current help window and moves it to the far right, unless
--- it is the last window left (where `:wincmd L` would no-op) or the
--- buffer was merely `:edit`ed rather than opened via `:help`.
---@param _file string
---@param buf   integer
---@param _opts vim.api.keyset.create_autocmd.callback_args
---@return nil
M.setup = function(_file, buf, _opts)
    -- Exclusively help windows, skip `:edit`ed doc files,
    if vim.bo[buf].buftype ~= "help" then
        return
    end

    -- Required: the API errors on the last non-floating window, where
    -- `:wincmd L` would merely no-op.
    if vim.fn.winlayout()[1] == "leaf" then
        return
    end

    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_config(win, { split = "right", win = -1 })
    vim.api.nvim_win_set_width(win, 90)
end

return M
