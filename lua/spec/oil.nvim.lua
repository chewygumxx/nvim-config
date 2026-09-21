#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/oil.nvim.lua
--
--

---@module "lazy"
---@module 'oil'

---@type LazyPluginSpec
local M = {
    "stevearc/oil.nvim",
    lazy = false, -- Documentation recommends against lazy-loading

    -- Optional dependencies
    dependencies = {
        { "nvim-mini/mini.icons", opts = {} },
        { "nvim-tree/nvim-web-devicons", opts = {} },
    },
}

---@type oil.SetupOpts
M.opts = {}

return M
