#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/oil.nvim.lua
--
--

---@module "lazy"
---@type LazySpec
local M = {
    'stevearc/oil.nvim',
    enabled = false,

    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
    -- Optional dependencies
    dependencies = {
        { "nvim-mini/mini.icons", opts = {}  },
        { "nvim-tree/nvim-web-devicons", opts = {} },
    },
}

---@module 'oil'
---@type oil.SetupOpts
M.opts = {}

return M
