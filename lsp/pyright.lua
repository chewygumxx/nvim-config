#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/pyright.lua
--
--

---@type vim.lsp.Config
local M = {
    settings = {
        python = {
            analysis = {
                -- ruff already covers linting/import-sorting, so
                -- pyright's job here is purely type analysis; opt into a
                -- level that surfaces real bugs (Optional/union misuse,
                -- etc.) rather than mirroring ruff's own checks.
                typeCheckingMode = "standard",
                autoImportCompletions = true,
            },
        },
    },
}

return M
