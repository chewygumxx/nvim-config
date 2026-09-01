#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- vim: foldlevel=3:foldmethod=expr:

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/dot_config/nvim/lua/util/visual_traversal.lua
--
--

--
-- Buffer local keymap settings for visual navigation/traversal
--

local M = {}

local traversal_keymaps = { 'j', 'k', '0', '$' }

local update_keymaps = function(bufnr)
    bufnr = bufnr or 0
    local enabled = vim.b[bufnr].cgxx_visual_traversal
    local status = "Visual Traversal: " .. (enabled and "ON" or "OFF")

    for _, key in ipairs(traversal_keymaps) do
        vim.keymap.set({ 'n', 'v' }, key, (enabled and 'g' .. key or key), {
            buf   = bufnr,
            remap = false,
            desc  = status
        })
    end

    if vim.g.cgxx_verbose then
        vim.print(status)
    end
end

M.enable = function(bufnr)
    bufnr = bufnr or 0
    vim.b[bufnr].cgxx_visual_traversal = true
    update_keymaps(bufnr)
end

M.disable = function(bufnr)
    bufnr = bufnr or 0
    vim.b[bufnr].cgxx_visual_traversal = false
    update_keymaps(bufnr)
end

M.toggle = function(bufnr)
    bufnr = bufnr or 0
    vim.b[bufnr].cgxx_visual_traversal = not vim.b[bufnr].cgxx_visual_traversal
    update_keymaps(bufnr)
end

local act_func = {
    toggle  = function(_) M.toggle()  end,
    enable  = function(_) M.enable()  end,
    disable = function(_) M.disable() end,
}
M.command = function(act)
    return act_func[act]
end

return M
