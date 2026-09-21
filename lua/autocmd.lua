#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only
--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/autocmd.lua
--
--
local M = {}

--- Registers the `BufReadPost` autocmd that restores the cursor to its
--- last position in the file (skipped if something already moved it,
--- e.g. `gF`, a line-number arg).
---@return nil
local cursor_last_position = function()
    vim.api.nvim_create_autocmd("BufReadPost", {
        desc     = "Move cursor to last position within file",
        group    = M.augroup_file_entry,
        callback = function()
            vim.schedule(function()
                -- Skip if the cursor was already moved (e.g. by gF, a line-number arg, etc.)
                local cur = vim.api.nvim_win_get_cursor(0)
                if cur[1] ~= 1 or cur[2] ~= 0 then
                    return
                end
                vim.cmd('silent! normal! g`"zvzz')
            end)
        end,
    })
end

--- Registers the `BufReadPost` autocmd that maps "q" to quit, buffer-local,
--- for buffers opened readonly or otherwise unmodifiable.
---@return nil
local unmodifiable_q_quit = function()
    vim.api.nvim_create_autocmd("BufReadPost", {
        desc     = "For unmodifiable buffers: Keymap (nv) q->quit ",
        group    = M.augroup_file_entry,
        callback = function(event)
            local bufnr = event.buf or 0
            if vim.bo[bufnr].readonly or not vim.bo[bufnr].modifiable then
                vim.keymap.set({ "n", "v" }, "q", "<cmd>q<CR>", {
                    buffer = bufnr,
                    desc   = "Quit read-only buffer",
                    remap  = false,
                })
            end
        end,
    })
end

--- Creates the shared "cgxx.file_entry" augroup and registers this
--- module's autocmds.
---@return nil
M.setup = function()
    ---@type integer
    M.augroup_file_entry = vim.api.nvim_create_augroup("cgxx.file_entry", {
        clear = true,
    })
    cursor_last_position()
    unmodifiable_q_quit()
    local header = require("util.header")
    if header then
        header.autocmd()
    end
end

return M
