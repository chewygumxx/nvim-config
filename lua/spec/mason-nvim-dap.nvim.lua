#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/mason-nvim-dap.nvim.lua
--
--

--
-- Bridges mason.nvim-installed DAP adapters to nvim-dap: wires up
-- dap.adapters/dap.configurations for everything in ensure_installed via
-- its built-in handlers. Installation itself is left to
-- mason-tool-installer.nvim.
-- https://github.com/jay-babu/mason-nvim-dap.nvim
--

---@module "lazy"

---@type LazyPluginSpec
local M = {
    "jay-babu/mason-nvim-dap.nvim",
    enabled      = vim.env.HERDR_ENV == nil and vim.env.TERMUX_VERSION == nil,
    lazy         = false,
    dependencies = {
        "mason-org/mason.nvim",
        "mfussenegger/nvim-dap",
    },
}

M.opts = {
    ensure_installed = {
        "python", -- debugpy
        "bash",   -- bash-debug-adapter
    },
    automatic_installation = false,
}

return M
