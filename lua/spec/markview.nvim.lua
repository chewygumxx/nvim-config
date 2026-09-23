#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/markview.nvim.lua
--
--

---@module "lazy"

---@type LazyPluginSpec
local M = {
    "OXY2DEV/markview.nvim",

    -- The README advises against lazy-loading citing preview loading delay.
    -- I can wait.
    lazy = true,
    ft = "markdown",

    dependencies = { "saghen/blink.cmp" },

    ---@type markview.config
    opts = {},
}

return M
