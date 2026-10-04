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

---@class (exact) cgxx.lint.RangePos
---@field line      integer
---@field character integer

---@class (exact) cgxx.lint.Range
---@field start cgxx.lint.RangePos
---@field end   cgxx.lint.RangePos

---@class (exact) cgxx.lint.LspDiagnosticItem
---@field range    cgxx.lint.Range
---@field severity integer
---@field message  string
---@field code?    string | integer

---@class (exact) cgxx.lint.EmmyLuaEntry
---@field file        string
---@field diagnostics cgxx.lint.LspDiagnosticItem[]

---@class (exact) cgxx.lint.ShuckLocation
---@field row    integer
---@field column integer

---@class (exact) cgxx.lint.ShuckViolation
---@field location     cgxx.lint.ShuckLocation
---@field end_location cgxx.lint.ShuckLocation
---@field severity     string
---@field message      string
---@field code?        string | integer

M.config = function()
    ---@type lint
    local lint         = require("lint")
    local lua_checker  = require("util.lua_checker")
    local yamllint     = require("util.yamllint")
    lint.linters_by_ft = {
        -- Switchable via XXLuaChecker; see util.lua_checker.
        lua    = lua_checker.linters(),
        python = { "ruff" },
        sh     = { "shellcheck" },
        sql    = { "sqlfluff" },
        -- shellcheck explicitly doesn't support zsh; shuck is the one
        -- linter here that understands zsh-specific syntax.
        zsh      = { "shuck" },
        yaml     = { "yamllint" },
        markdown = { "markdownlint-cli2" },
        -- jsonlint rejects comments, so only plain "json" is linted;
        -- "jsonc" (tsconfig.json, VSCode settings, etc.) relies on
        -- jsonls's own diagnostics instead.
        json = { "jsonlint" },
    }

    -- sqlfluff refuses to run without a dialect and nvim-lint's built-in
    -- definition doesn't set one; default to sqlite, same as the
    -- conform.nvim formatter override.
    ---@type lint.Linter
    local sqlfluff        = vim.tbl_extend("force", lint.linters.sqlfluff, {
        args = { "lint", "--format=json", "-", "--dialect", "sqlite" },
    })
    lint.linters.sqlfluff = sqlfluff

    -- markdownlint-cli2 reads the buffer on stdin, so it looks for its
    -- configuration in its cwd, which is Neovim's rather than the
    -- buffer's. Run it from the buffer's project when that configures it,
    -- and otherwise hand it this repository's `.markdownlint-cli2.jsonc`.
    ---@type lint.Linter
    local mdlint         = vim.deepcopy(lint.linters["markdownlint-cli2"])
    local mdlint_markers = {
        ".markdownlint-cli2.jsonc",
        ".markdownlint-cli2.yaml",
        ".markdownlint-cli2.cjs",
        ".markdownlint-cli2.mjs",
        ".markdownlint.jsonc",
        ".markdownlint.json",
        ".markdownlint.yaml",
        ".markdownlint.yml",
        ".markdownlint.cjs",
        ".markdownlint.mjs",
    }

    -- nvim-lint resolves a linter given as a function on every run, but
    -- annotates the table as holding only `lint.Linter`
    ---@diagnostic disable-next-line: assign-type-mismatch
    lint.linters["markdownlint-cli2"] = function()
        local root = vim.fs.root(0, mdlint_markers)
        if root then
            return vim.tbl_extend("force", mdlint, { cwd = root })
        end
        local fallback = vim.fn.stdpath("config") .. "/.markdownlint-cli2.jsonc"
        return vim.tbl_extend("force", mdlint, {
            args = { "--config", fallback, "-" },
        })
    end

    -- Run on the saved file from the buffer's directory rather than
    -- stdin, so the repository's own `.yamllint*` applies; see
    -- util.yamllint.
    lint.linters.yamllint = yamllint.linter

    -- Not bundled with nvim-lint. One of XXLuaChecker's two options:
    -- lua-language-server's own --check mode, run headless against the
    -- workspace root (needed to resolve vim/plugin globals) since a
    -- single-file check can't see them. --check_format=json writes the
    -- report to <logpath>/check.json rather than stdout, so the parser
    -- reads it back off disk and filters it down to the current buffer.
    local luals_check_dir    = vim.fn.stdpath("cache") .. "/luals-check"
    lint.linters.luals_check = {
        name = "luals_check",
        cmd = "lua-language-server",
        stdin = false,
        ignore_exitcode = true,
        args = {
            function()
                return "--check="
                    .. (vim.fs.root(0, { ".luarc.json", ".emmyrc.json" })
                        or vim.fn.getcwd())
            end,
            "--checklevel=Hint",
            "--check_format=json",
            "--force-accept-workspace",
            "--logpath=" .. luals_check_dir,
        },
        parser = function()
            local ok, lines = pcall(
                vim.fn.readfile,
                luals_check_dir .. "/check.json"
            )
            if not ok then
                return {}
            end
            local decoded_ok, report = pcall(
                vim.json.decode,
                table.concat(lines, "\n")
            )
            if not decoded_ok then
                return {}
            end
            ---@cast report table<string, cgxx.lint.LspDiagnosticItem[]>

            ---@type vim.Diagnostic[]
            local diagnostics = {}
            for _, item in ipairs(report[vim.uri_from_bufnr(0)] or {}) do
                table.insert(diagnostics, {
                    lnum = item.range.start.line,
                    col = item.range.start.character,
                    end_lnum = item.range["end"].line,
                    end_col = item.range["end"].character,
                    severity = item.severity,
                    message = item.message,
                    code = item.code,
                    source = "lua-language-server",
                })
            end
            return diagnostics
        end,
    }

    -- Not bundled with nvim-lint. XXLuaChecker's other option: EmmyLua's
    -- headless checker, also run against the workspace root and filtered
    -- to the current buffer.
    lint.linters.emmylua_check = {
        name = "emmylua_check",
        cmd = "emmylua_check",
        stdin = false,
        ignore_exitcode = true,
        args = {
            function()
                return vim.fs.root(0, { ".luarc.json", ".emmyrc.json" })
                    or vim.fn.getcwd()
            end,
            "--output-format",
            "json",
        },
        parser = function(output)
            if output == "" then
                return {}
            end
            local ok, report = pcall(vim.json.decode, output)
            if not ok then
                return {}
            end
            ---@cast report cgxx.lint.EmmyLuaEntry[]

            local fname = vim.api.nvim_buf_get_name(0)
            ---@type vim.Diagnostic[]
            local diagnostics = {}
            for _, entry in ipairs(report) do
                if entry.file == fname then
                    for _, item in ipairs(entry.diagnostics) do
                        table.insert(diagnostics, {
                            lnum = item.range.start.line,
                            col = item.range.start.character,
                            end_lnum = item.range["end"].line,
                            end_col = item.range["end"].character,
                            severity = item.severity,
                            message = item.message,
                            code = item.code,
                            source = "EmmyLua",
                        })
                    end
                end
            end
            return diagnostics
        end,
    }

    -- Not bundled with nvim-lint.
    lint.linters.shuck = {
        name = "shuck",
        cmd = "shuck",
        stdin = true,
        ignore_exitcode = true,
        args = {
            "check",
            "-",
            "--output-format",
            "json",
            "--stdin-filename",
            function()
                return vim.api.nvim_buf_get_name(0)
            end,
        },
        parser = function(output)
            if output == "" then
                return {}
            end
            local ok, violations = pcall(vim.json.decode, output)
            if not ok then
                return {}
            end
            ---@cast violations cgxx.lint.ShuckViolation[]
            ---@type vim.Diagnostic[]
            local diagnostics = {}
            for _, violation in ipairs(violations) do
                table.insert(diagnostics, {
                    lnum = violation.location.row - 1,
                    col = violation.location.column - 1,
                    end_lnum = violation.end_location.row - 1,
                    end_col = violation.end_location.column - 1,
                    severity = violation.severity == "error"
                        and vim.diagnostic.severity.ERROR
                        or vim.diagnostic.severity.WARN,
                    message = violation.message,
                    code = violation.code,
                    source = "shuck",
                })
            end
            return diagnostics
        end,
    }

    ---@type integer
    local augroup = vim.api.nvim_create_augroup("XXLint", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = augroup,
        callback = function(args)
            ---@type string
            local ft = vim.bo[args.buf].filetype
            -- nvim-lint runs a compound filetype's every component, so
            -- "yaml.gitlab" reaches yamllint too.
            if vim.split(ft, ".", { plain = true })[1] == "yaml" then
                lint.try_lint(nil, { cwd = yamllint.cwd(args.buf) })
                return
            end
            if ft ~= "lua" then
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
