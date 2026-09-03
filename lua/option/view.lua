#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/option/view.lua
--
--

--
-- Visual interface option settings
--

local M = {}

local opts = {
    -- Color
    termguicolors = true,

    -- Margin
    number         = true,
    relativenumber = true,
    scrolloff      = 5,
    
    -- Window Splitting
    splitright = true,

    -- Restore view when jumping
    jumpoptions = "view",
}

M.setup = function()
    for opt, value in pairs(opts) do
        vim.api.nvim_set_option_value(opt, value, {})
    end
end

return M

