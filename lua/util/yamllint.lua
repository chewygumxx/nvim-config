#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/yamllint.lua
--
--

--
-- yamllint as nvim-lint should run it: on the saved file, from the
-- directory holding the repository's `.yamllint`, `.yamllint.yaml` or
-- `.yamllint.yml`, with the path given relative to it.
--
-- nvim-lint's bundled definition pipes the buffer through stdin from
-- Neovim's process cwd. yamllint looks for its configuration upward from
-- the directory it runs in, so that found whichever repository Neovim
-- was started in. And yamllint matches `ignore:` the way gitignore does,
-- against the path exactly as it was given, so a stdin buffer, or an
-- absolute path, matches no pattern holding a slash. Both hold for
-- `yamllint .` at the root, which is the invocation a configuration is
-- written for. yaml-language-server reads none of this: its settings
-- come from `lsp/yamlls.lua` alone.
--

local M = {}

--- The names yamllint looks for, in its order of preference.
---@type string[]
M.files = { ".yamllint", ".yamllint.yaml", ".yamllint.yml" }

local severities = {
    error   = vim.diagnostic.severity.ERROR,
    warning = vim.diagnostic.severity.WARN,
}

--- `path:line:col: [severity] message (rule)`, yamllint's `parsable`
--- format. The path is matched greedily so a colon inside it is kept.
local pattern = "^(.+):(%d+):(%d+): %[(%a+)%] (.+) %(([%w-]+)%)$"

--- The directory yamllint runs in for `buf`: the nearest one holding a
--- configuration, or the buffer's own where none does, leaving yamllint
--- to fall back on the user's. Nil for a buffer with no file behind it.
--- Searched from the name, since `vim.fs.root(buf)` starts from the
--- process cwd for any buffer with a `buftype`.
---@param buf integer
---@return string?
M.cwd = function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then
        return nil
    end
    return vim.fs.root(name, M.files) or vim.fs.dirname(name)
end

--- `buf`'s path relative to `M.cwd`, which is what `ignore:` matches.
---@param buf integer
---@return string
M.path = function(buf)
    local name = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
    local cwd  = M.cwd(buf)
    return cwd and vim.fs.relpath(cwd, name) or name
end

--- Diagnostics for `buf` out of yamllint's `parsable` output, whose
--- paths are relative to `cwd`. A line about any other file is dropped
--- rather than misplaced.
---@param output string
---@param buf    integer
---@param cwd?   string  the directory yamllint ran in
---@return vim.Diagnostic[]
M.parse = function(output, buf, cwd)
    local path = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
    local base = cwd or M.cwd(buf) or ""
    ---@type vim.Diagnostic[]
    local diagnostics = {}
    for line in vim.gsplit(output, "\n", { plain = true }) do
        local file, lnum, col, severity, message, rule = line:match(pattern)
        if file and not vim.startswith(file, "/") then
            file = vim.fs.joinpath(base, file)
        end
        if file and vim.fs.normalize(file) == path then
            table.insert(diagnostics, {
                bufnr    = buf,
                lnum     = tonumber(lnum) - 1,
                col      = tonumber(col) - 1,
                severity = severities[severity],
                message  = message,
                code     = rule,
                source   = "yamllint",
            })
        end
    end
    return diagnostics
end

--- The current buffer's path for `args`. nvim-lint would otherwise
--- append the absolute one, which `ignore:` cannot match.
---@return string
local current = function()
    return M.path(vim.api.nvim_get_current_buf())
end

--- Replaces nvim-lint's bundled `yamllint`. The directory it runs in is
--- passed per buffer from `M.cwd`, since a linter's own `cwd` is fixed.
---@type lint.Linter
M.linter = {
    name            = "yamllint",
    cmd             = "yamllint",
    stdin           = false,
    append_fname    = false,
    stream          = "stdout",
    ignore_exitcode = true,
    args            = { "--format", "parsable", current },
    parser          = M.parse,
}

return M
