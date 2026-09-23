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
        lua      = { "selene" },
        python   = { "ruff" },
        sh       = { "shellcheck" },
        yaml     = { "yamllint" },
        markdown = { "markdownlint-cli2" },
        -- jsonlint rejects comments, so only plain "json" is linted;
        -- "jsonc" (tsconfig.json, VSCode settings, etc.) relies on
        -- jsonls's own diagnostics instead.
        json = { "jsonlint" },
    }

    ---@type integer
    local augroup = vim.api.nvim_create_augroup("XXLint", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = augroup,
        callback = function(args)
            if vim.bo[args.buf].filetype ~= "lua" then
                lint.try_lint()
                return
            end

            -- The bundled `selene` linter has no `cwd` of its own and
            -- falls back to Neovim's process cwd, so `selene.toml` (and
            -- the std files it references) only resolve when Neovim
            -- happens to have been started from the repo root; resolve
            -- it per-buffer instead.
            lint.try_lint(nil, {
                cwd = vim.fs.root(args.buf, "selene.toml"),
            })
        end,
    })
end

return M
