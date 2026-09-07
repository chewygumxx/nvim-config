#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/fzf-lua.lua
--
--

---@module "lazy"
---@type LazySpec
local M =  {
    "ibhagwan/fzf-lua",
    enabled = false,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "nvim-treesitter/nvim-treesitter-context",
    },

    opts = {},
}

return M
