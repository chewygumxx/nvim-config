#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/telescope-undo.lua
--
--

---@module "lazy"

---@type LazyPluginSpec
local M = {
    "debugloop/telescope-undo.nvim",

    -- An extension of telescope.nvim, and elided with it in
    -- lua/plugin.lua: loaded on its own it would `require` nothing
    dependencies = {
        {
            "nvim-telescope/telescope.nvim",
            dependencies = { "nvim-lua/plenary.nvim" },
        },
    },
    keys = {
        {
            "<leader>u",
            "<cmd>Telescope undo<cr>",
            desc = "undo history",
        },
    },
    ---@type cgxx.spec.telescope.Opts
    opts = {
        -- Only this extension's own table: telescope's `defaults` belong to
        -- lua/spec/telescope.nvim.lua, and each extension to its own spec
        extensions = {
            undo = {},
        },
    },
    config = function(_, opts)
        -- telescope's `setup` merges across calls, so each spec calling it
        -- with only its own namespace is safe
        require("telescope").setup(opts)
        require("telescope").load_extension("undo")
    end,
}

return M
