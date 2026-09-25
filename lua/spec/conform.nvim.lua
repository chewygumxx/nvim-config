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
        python   = { "ruff_format" },
        sh       = { "shfmt" },
        sql      = { "sqlfluff" },
        -- shfmt has no zsh dialect; shuck is the one formatter here that
        -- understands zsh-specific syntax.
        zsh = { "shuck" },
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
-- defaults to "all".
M.opts.formatters.prettier_jsonc = {
    inherit = "prettier",
    append_args = { "--trailing-comma", "none" },
}

-- sqlfluff refuses to run without a dialect, and conform's built-in
-- definition sets require_cwd = true against markers (.sqlfluff,
-- pyproject.toml, etc.) that a fresh SQL file won't have yet; default to
-- sqlite and always run, so a project's own .sqlfluff can still override
-- the dialect later.
M.opts.formatters.sqlfluff = {
    append_args = { "--dialect", "sqlite" },
    require_cwd = false,
}

-- Not bundled with conform.nvim. --dialect is forced rather than relying
-- on shuck's own auto-detection, same rationale as sqlfluff's --dialect
-- above: deterministic regardless of shebang or file extension.
M.opts.formatters.shuck = {
    command = "shuck",
    stdin   = true,
    cwd     = function(_, ctx)
        return vim.fs.root(ctx.dirname, { ".shuck.toml", "shuck.toml" })
    end,
    args    = function(_, ctx)
        local ret     = {
            "format",
            "-",
            "--stdin-filename",
            ctx.filename,
            "--dialect",
            "zsh",
        }
        local default = {
            "--indent-style",
            "space",
            "--indent-width",
            "4",
            "--space-redirects",
            "--keep-padding",
            "--switch-case-indent",
        }

        if not vim.fs.root(ctx.dirname, { ".shuck.toml", "shuck.toml" }) then
            vim.list_extend(ret, default)
        end

        return ret
    end,
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
