#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/bashls.lua
--
--

---@type vim.lsp.Config
local M = {
    cmd          = { "bash-language-server", "start" },
    filetypes    = { "bash", "sh" },
    root_markers = { ".git" },
    settings     = {
        bashIde = {
            -- Not recursive, unlike the server's own "**/*@(...)": opening
            -- a script directly in $HOME would otherwise index all of it.
            -- $GLOB_PATTERN overrides it per session.
            globPattern = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
            -- Surface diagnostics for `source`/`.` targets bashls can't
            -- statically resolve, instead of silently ignoring them.
            enableSourceErrorDiagnostics = true,
            -- Search all shell scripts in the workspace for
            -- textDocument/workspaceSymbol, not just open buffers.
            includeAllWorkspaceSymbols = true,
        },
    },
}

return M
