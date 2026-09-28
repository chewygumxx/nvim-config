#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/option/view.lua
--
--

--
-- Visual interface option settings
--

local M = {}

local opts = {
    -- Color
    termguicolors = true,

    -- Gutter
    number         = true,
    relativenumber = true,

    -- Scroll
    --
    -- No 'scroll' here, deliberately. It is window local and Neovim
    -- recomputes it to half the window height on every resize, so a value
    -- set once at startup holds for one window until the first split and
    -- never again. The five line scroll distance is carried on the keys
    -- instead, by `keymap.scroll_distance`.
    scrolloff = 5,

    -- Window Splitting
    splitright = true,

    -- Restore view when jumping
    jumpoptions = "view",
}

--- Applies this module's global option values.
---@return nil
M.setup = function()
    for opt, value in pairs(opts) do
        vim.api.nvim_set_option_value(opt, value, {})
    end

    -- Can't join `opts`: the value is derived from 'statusline' itself, by
    -- splicing a git repository segment over the default's leading `%f`
    require("util.statusline").setup()
end

return M
