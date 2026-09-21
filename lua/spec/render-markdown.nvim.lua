#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/render-markdown.nvim.lua
--
--

---@module "lazy"
---@module "render-markdown"

---@type LazyPluginSpec
local M = {
    "MeanderingProgrammer/render-markdown.nvim",

    ft = { "markdown" },

    ---@type render.md.UserConfig
    opts = {},
}

return M
