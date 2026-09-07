#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/yazi.nvim.lua
--
--

---@module "vim"
---@module "lazy"

---@type LazySpec
local M = {
    "mikavilpas/yazi.nvim",
    enabled = true,

    version = "*",
    event = "VeryLazy",
    dependencies = {
        { "nvim-lua/plenary.nvim", lazy = true },
    },

}

M.keys = {
    {
        "<leader>-",
        mode = { "n", "v" },
        "<cmd>Yazi<cr>",
        desc = "Open yazi at the current file",
    },
    {
        "<leader>cw",
        "<cmd>Yazi cwd<cr>",
        desc = "Open the file manager in nvim's working directory",
    },
    {
        "<c-up>",
        "<cmd>Yazi toggle<cr>",
        desc = "Resume the last yazi session",
    },
}

---@type YaziConfig | {}
M.opts = {
    -- if true, `M.init = function() vim.g.loadednetrwPlugin = 1 end`
    open_for_directories = true,
    keymaps = {
        show_help = "<f1>",
    },
}

M.init = function()
    -- mark netrw as loaded so it's not loaded at all.
    -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
    vim.g.loaded_netrwPlugin = 1
end

return M
