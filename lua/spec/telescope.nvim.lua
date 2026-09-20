#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/telescope.nvim.lua
--
--

-- TODO(@chewygumxx): [LOW] Incomplete as a fzf-lua contingency: restore a
-- version pin (was `version = "*"`), call
-- require("telescope").load_extension("fzf") for telescope-fzf-native
-- below to have any effect.
---@module "lazy"
---@type LazySpec
local M = {
    "nvim-telescope/telescope.nvim",

    -- Not lazy: the quickfix/loclist redirect below (`config`, not `opts`)
    -- must be registered before anything ever opens one, which can happen
    -- before Telescope would otherwise have been triggered to load.
    lazy = false,

    opts = {},

    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
}

M.config = function(_, opts)
    require("telescope").setup(opts)

    -- Route quickfix/location-list windows through Telescope's own picker
    -- instead of Neovim's native quickfix UI. `FileType qf` fires for both;
    -- `getwininfo().loclist` tells them apart.
    vim.api.nvim_create_autocmd("FileType", {
        pattern  = "qf",
        callback = function()
            local win = vim.api.nvim_get_current_win()
            local loc = vim.fn.getwininfo(win)[1].loclist == 1
            vim.schedule(function()
                local builtin = require("telescope.builtin")
                if loc then
                    vim.cmd("lclose")
                    builtin.loclist()
                else
                    vim.cmd("cclose")
                    builtin.quickfix()
                end
            end)
        end,
    })
end

return M
