#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/mason.nvim.lua
--
--

--
-- LSP/DAP/linter/formatter installer, for portability to machines
-- (e.g. Termux) that don't have servers available as system packages.
-- https://github.com/mason-org/mason.nvim
--

---@module "lazy"
---@module "mason"

---@type LazyPluginSpec
local M = {
    "mason-org/mason.nvim",
    lazy = false,

    ---@type MasonSettings
    opts = {},
}

return M
