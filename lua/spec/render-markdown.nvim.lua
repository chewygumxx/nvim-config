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

---@type LazyPluginSpec
local M = {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = false,

    ft = { "markdown" },
    opts = {},
}

return M
