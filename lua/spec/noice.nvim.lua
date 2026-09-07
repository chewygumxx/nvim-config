#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/noice.nvim.lua
--
--

--
-- https://github.com/folke/noice.nvim
--

---@module "lazy"
---@type LazySpec
local M = {
    "folke/noice.nvim",
    enabled = false,
    event = "VeryLazy",

    dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
    },

    opts = {},
}

M.opts.lsp = {
    -- Override markdown rendering so that **cmp** and other plugins use **Treesitter**
    override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
    },
}

M.opts.presets = {
    bottom_search         = true,   -- Use a classic bottom cmdline for search
    command_palette       = true,   -- Position the cmdline and popupmenu together
    long_message_to_split = true,   -- Long messages will be sent to a split
    inc_rename            = false,  -- Enables an input dialog for inc-rename.nvim
    lsp_doc_border        = false,  -- Add a border to hover docs and signature help
}

return M
