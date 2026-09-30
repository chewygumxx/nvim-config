#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/ts_query_ls.lua
--
--

--
-- nvim-lspconfig also set `vim.g.query_lint_on = {}` here, to stop Neovim's
-- own query linter reporting everything this server does. It is not
-- carried over: `ftplugin/query.lua` reads `vim.g.query_lint_on or {}`, so
-- that linter is already off unless something switches it on.
--

---@type vim.lsp.Config
local M = {
    cmd       = { "ts_query_ls" },
    filetypes = { "query" },
    -- `.tsqueryrc.json` exists here for the `Queries` CI job, and so
    -- anchors the workspace at the repository root
    root_markers = { ".tsqueryrc.json", ".git" },
    init_options = {
        parser_aliases             = {
            ecma     = "javascript",
            jsx      = "javascript",
            php_only = "php",
        },
        parser_install_directories = {
            vim.fs.joinpath(vim.fn.stdpath("data"), "site", "parser"),
        },
    },
}

--- The `query` ftplugin sets its own omnifunc, which Neovim's LSP defaults
--- leave alone, so the server's completion has to be asked for.
---@param _   vim.lsp.Client
---@param buf integer
---@return nil
M.on_attach = function(_, buf)
    vim.bo[buf].omnifunc = "v:lua.vim.lsp.omnifunc"
end

return M
