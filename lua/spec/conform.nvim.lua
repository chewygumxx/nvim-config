#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/conform.nvim.lua
--
--

--
-- Formats the buffer on save, using per-filetype formatters resolved
-- through mason-tool-installer.
-- https://github.com/stevearc/conform.nvim
--

---@module "lazy"
---@type LazySpec
local M = {
    "stevearc/conform.nvim",
    lazy = false,
}

---@module "conform"
---@type conform.setupOpts
M.opts = {
    formatters_by_ft = {
        javascript      = { "prettier" },
        javascriptreact = { "prettier" },
        typescript      = { "prettier" },
        typescriptreact = { "prettier" },
    },
    formatters = {},
    format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
    },
}

M.opts.formatters_by_ft.lua = function(bufnr)
    if vim.fs.root(bufnr, { ".luafmt.toml", "luafmt.toml" }) then
        return { "luafmt" }
    end
    if vim.fs.root(bufnr, { ".stylua.toml", "stylua.toml" }) then
        return { "stylua" }
    end
    return { "luafmt" }
end

-- Not bundled with conform.nvim
M.opts.formatters.luafmt = {
    command = "luafmt",
    args    = { "--stdin" },
    stdin   = true,
    cwd     = function(_, ctx)
        return vim.fs.root(ctx.dirname, { ".luafmt.toml", "luafmt.toml" })
    end,
}

return M
