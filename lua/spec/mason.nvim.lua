#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/mason.nvim.lua
--
--

--
-- LSP/DAP/linter/formatter installer, for portability to machines
-- (e.g. Termux) that don't have servers available as system packages.
-- https://github.com/mason-org/mason.nvim
--

---@module "lazy"
---@type LazySpec
local M = {
    "mason-org/mason.nvim",
    enabled = true,
    lazy    = false,
    opts    = {},
}

return M
