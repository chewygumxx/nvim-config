#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/harpoon.lua
--
--

--
-- Marks and jumps between a small, per-project list of files.
-- https://github.com/ThePrimeagen/harpoon/tree/harpoon2
--

---@module "lazy"
---@type LazySpec
local M = {
    "ThePrimeagen/harpoon",
    branch       = "harpoon2",
    dependencies = {
        { "nvim-lua/plenary.nvim", lazy = true },
    },
}

M.keys = {
    {
        "<leader>ha",
        function() require("harpoon"):list():add() end,
        desc = "Harpoon: add file",
    },
    {
        "<C-e>",
        function()
            local harpoon = require("harpoon")
            harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon: toggle quick menu",
    },
    {
        "<C-h>",
        function() require("harpoon"):list():select(1) end,
        desc = "Harpoon: select 1",
    },
    {
        "<C-t>",
        function() require("harpoon"):list():select(2) end,
        desc = "Harpoon: select 2",
    },
    {
        "<C-n>",
        function() require("harpoon"):list():select(3) end,
        desc = "Harpoon: select 3",
    },
    {
        "<C-s>",
        function() require("harpoon"):list():select(4) end,
        desc = "Harpoon: select 4",
    },
    {
        "<C-S-P>",
        function() require("harpoon"):list():prev() end,
        desc = "Harpoon: previous in list",
    },
    {
        "<C-S-N>",
        function() require("harpoon"):list():next() end,
        desc = "Harpoon: next in list",
    },
}

M.opts = {}

-- `harpoon:setup(opts)` is a colon method call (harpoon relies on the
-- implicit `self`, e.g. for its own autocmds); lazy.nvim's automatic
-- `require(...).setup(opts)` handling would call it without one.
M.config = function(_, opts) require("harpoon"):setup(opts) end

return M
