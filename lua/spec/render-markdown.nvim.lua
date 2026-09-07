#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/render-markdown.nvim.lua
--
--

---@module "lazy"
---@type LazySpec
local M = {
    'MeanderingProgrammer/render-markdown.nvim',
    enabled = false,

    ft = { "markdown" },
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'nvim-tree/nvim-web-devicons'
    },
    opts = {},
}

return M
