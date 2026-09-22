#!/usr/bin/env lua
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

    -- Margin
    number         = true,
    relativenumber = true,
    scrolloff      = 5,

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
end

return M
