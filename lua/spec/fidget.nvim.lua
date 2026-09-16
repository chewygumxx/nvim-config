#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/fidget.nvim.lua
--
--

--
-- LSP progress indicator: shows a corner popup while a server reports
-- $/progress (e.g. workspace indexing), and fades it out on completion.
-- https://github.com/j-hui/fidget.nvim
--

---@module "lazy"
---@type LazySpec
local M = {
    "j-hui/fidget.nvim",
    lazy = false,
    opts = {},
}

return M
