#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- luacheck: globals vim
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

    opts = {},

    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
}

return M
