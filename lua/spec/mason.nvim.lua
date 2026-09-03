#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

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
}

M.opts = {}

return M
