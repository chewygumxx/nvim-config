#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

-- 
-- 
-- ~/.config/nvim/lua/autocmd.lua
-- 
-- 

local M = {}

local cursor_last_position = function()
    vim.api.nvim_create_autocmd("BufReadPost", {
        desc  = "Move cursor to last position within file",
        group = M.augroup_file_entry,
        callback = function () vim.schedule( function ()
            -- Skip if the cursor was already moved (e.g. by gF, a line-number arg, etc.)
            local cur = vim.api.nvim_win_get_cursor(0)
            if cur[1] ~= 1 or cur[2] ~= 0 then
                return
            end
            vim.cmd('silent! normal! g`"zvzz')
        end) end
    })
end

local unmodifiable_q_quit = function()
    vim.api.nvim_create_autocmd("BufReadPost", {
        desc  = "For unmodifiable buffers: Keymap (nv) q->quit ",
        group = M.augroup_file_entry,
        callback = function(event)
            local bufnr = event.buf or 0
            if vim.bo[bufnr].readonly or not vim.bo[bufnr].modifiable then
                vim.keymap.set({ "n", "v" }, "q", "<cmd>q<CR>", {
                    buffer = bufnr,
                    desc   = "Quit read-only buffer",
                    remap  = false,
                })
            end
        end
    })
end

M.setup = function()
    M.augroup_file_entry = vim.api.nvim_create_augroup("cgxx.file_entry", { clear = true })
    cursor_last_position()
    unmodifiable_q_quit()
    local header = _G.require_guard("util.header")
    if header then
        header.autocmd()
    end
end

return M
