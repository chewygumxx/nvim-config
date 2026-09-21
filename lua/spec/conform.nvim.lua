#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/conform.nvim.lua
--
--

--
-- Formats the buffer on save, using per-filetype formatters resolved
-- through mason-tool-installer.
-- https://github.com/stevearc/conform.nvim
--

---@module "lazy"
---@type LazyPluginSpec
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
        json            = { "prettier" },
        jsonc           = { "prettier_jsonc" },
        yaml            = { "prettier" },
        -- Explicit, so format_on_save never falls back to remark_ls: its
        -- formatter forces "*" bullets and mangles YAML frontmatter it
        -- doesn't recognize.
        markdown = { "prettier" },
        toml     = { "tombi" },
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

-- Unlike prettier's "json" parser, "jsonc" honors `trailingComma` and
-- defaults to "all". A repo-local `.prettierrc`/`package.json` override can
-- disable that, but only within that repo's own tree, e.g. this repo's own
-- `.repo-metadata.jsonc`; a jsonc file edited outside such a repo would still
-- get trailing commas, which not every consumer of "JSON with comments"
-- tolerates. Force "none" here so it holds regardless of project.
M.opts.formatters.prettier_jsonc = {
    inherit = "prettier",
    append_args = { "--trailing-comma", "none" },
}

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
