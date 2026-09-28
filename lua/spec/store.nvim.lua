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

    -- No markview.nvim: it would render the previews, but it is elided in
    -- lua/plugin.lua, so a dependency on it loads nothing
    dependencies = {
        --{ "3rd/image.nvim", opts = {} },
    },

    ---@type UserConfig
    opts = {
        layout = "tab", -- recommended when using image preview
    },
}

return M
