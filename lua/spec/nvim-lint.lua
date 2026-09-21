#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/nvim-lint.lua
--
--

--
-- Lints the buffer on write, using per-filetype linters resolved through
-- mason-tool-installer.
-- https://github.com/mfussenegger/nvim-lint
--

---@module "lazy"
---@type LazyPluginSpec
local M = {
    "mfussenegger/nvim-lint",
    event = "VeryLazy",
}

M.config = function()
    local lint         = require("lint")
    lint.linters_by_ft = {
        lua = { "selene" },
    }

    -- The bundled `selene` linter has no `cwd` of its own and falls back to
    -- Neovim's process cwd, so `selene.toml` (and the std files it
    -- references) only resolve when Neovim happens to have been started
    -- from the repo root; resolve it per-buffer instead.
    local augroup = vim.api.nvim_create_augroup("XXLint", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = augroup,
        pattern = "*.lua",
        callback = function(args)
            lint.try_lint(nil, {
                cwd = vim.fs.root(args.buf, "selene.toml"),
            })
        end,
    })
end

return M
