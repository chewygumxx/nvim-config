#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/store.nvim.lua
--
--

---@module "lazy"
---@module "store"

---@type LazyPluginSpec
local M = {
    "alex-popov-tech/store.nvim",
    lazy = true,
    cmd = "Store",

    dependencies = {
        { "OXY2DEV/markview.nvim", opts = {} },
        --{ "3rd/image.nvim", opts = {} },
    },

    ---@type UserConfig
    opts = {
        layout = "tab", -- recommended when using image preview
    },
}

return M
