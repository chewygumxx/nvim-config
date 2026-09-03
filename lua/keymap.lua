#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/keymap.lua
--
--

--
-- Neovim configuration of keymaps
--

local M = {}

vim.g.mapleader  = "\\"
vim.o.timeoutlen = 1000  -- Time to complete keymap sequence
vim.o.showcmd    = true  -- Show keystrokes right of message buffer

M.clear_hlsearch = function(lhs, desc)
    local lhs  = lhs  or '<leader>h'
    local desc = desc or ":noh - Clear highlight of search match"
    vim.keymap.set({ 'n' }, lhs, '<cmd>noh<CR>', { desc = desc })
end

M.toggle_relativenumber = function(lhs, desc)
    local lhs  = lhs  or '<leader>rn'
    local desc = desc or "Toggle relativenumber"
    vim.keymap.set({ 'n' }, lhs, function() 
        vim.o.relativenumber = not vim.o.relativenumber
    end, { desc = desc })
end

M.blink_relativenumber = function(lhs, desc)
    local lhs  = lhs  or '<leader>nn'
    local desc = desc or "Blink relativenumber"
    vim.keymap.set('n', lhs, function()
        local old_relativenumber = vim.o.relativenumber
        vim.o.relativenumber = not old_relativenumber
        vim.defer_fn(function()
            vim.o.relativenumber = old_relativenumber
        end, 2000)
    end, { desc = desc })
end

M.blink_linenumber = function(lhs, desc)
    local lhs  = lhs  or '<leader>ln'
    local desc = desc or "Blink line number in gutter"
    vim.keymap.set({ 'n' }, lhs, function() 
        local old_o_number = vim.o.number
        local old_o_relativenumber = vim.o.relativenumber
        local old_hl_linenr = vim.api.nvim_get_hl(0, { name = "LineNr" })

        vim.api.nvim_set_hl(0, "LineNr", { link = "ErrorMsg" })
        vim.o.number = true
        vim.o.relativenumber = false

        vim.defer_fn(function()
            vim.api.nvim_set_hl(0, "LineNr", old_hl_linenr)
            vim.o.number = old_o_number
            vim.o.relativenumber = old_o_relativenumber
        end, 3000)
    end, { desc = desc })
end

M.format_buffer = function(lhs, desc)
    local lhs  = lhs  or '<leader>tw'
    local desc = desc or "Format buffer line wrapping according to textwidth"
    vim.keymap.set({ 'n' }, lhs, 'gggqG', { desc = desc })
end

M.inspect = function(lhs, desc)
    local lhs  = lhs  or '<leader>in'
    local desc = desc or ":Inspect highlight groups under cursor"
    vim.keymap.set({ 'n' }, lhs, '<cmd>Inspect<CR>', { desc = desc })
end

M.reload_foldmethod = function(lhs, desc)
    local lhs  = lhs  or '<leader>rf'
    local desc = desc or "Reload foldmethod"
    vim.keymap.set({ 'n' }, lhs, function()
        vim.o.foldmethod = vim.o.foldmethod
        vim.print("foldmethod=" .. vim.o.foldmethod) 
    end, { desc = desc })
end

M.visual_indent_persist = function(indent, dedent, desc)
    local indent = indent or '>'
    local dedent = dedent or '<'
    local desc   = desc   or "Remain in visual mode after indenting"
    vim.keymap.set('x', indent, '>gv', { desc = desc })
    vim.keymap.set('x', dedent, '<gv', { desc = desc })
end

M.file_goto = function(lhs, desc)
    local lhs  = lhs  or "gf"
    local desc = desc or "Open file and if provided, go to line number"
    vim.keymap.set({ 'n', 'x' }, lhs, 'gF', { desc = desc })
end

M.file_create_or_open = function(lhs, desc)
    local lhs  = lhs  or "gF"
    local desc = desc or "Create or open new file according to path under cursor"
    vim.keymap.set({ 'n', 'x' }, lhs, '<cmd>e <cfile><CR>', { desc = desc })
end

M.blackhole_register = function()
    vim.keymap.set({ 'n' }, 'x', '"_x', {
        desc = "Blackhole Register: Single character deletion"
    })
    vim.keymap.set({ 'v' }, 'p', '"_dP', {
        desc = "Blackhole Register: Pasted over selection"
    })
end

M.setup = function()
    M.clear_hlsearch("<leader>h")
    M.toggle_relativenumber("<leader>rn")
    M.blink_relativenumber("<leader>nn")
    M.blink_linenumber("<leader>ln")
    M.format_buffer("<leader>tw")
    M.inspect("<leader>in")
    M.reload_foldmethod("<leader>rf")

    -- Without arguments, replace native keymaps
    M.visual_indent_persist()
    M.file_goto()
    M.file_create_or_open()

    -- Doesn't accept arguments
    M.blackhole_register()
end

return M
