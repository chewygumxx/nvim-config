#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/remark_ls.lua
--
--

---@type vim.lsp.Config
local M = {
    cmd          = { "remark-language-server", "--stdio" },
    filetypes    = { "markdown" },
    root_markers = {
        ".remarkrc",
        ".remarkrc.json",
        ".remarkrc.js",
        ".remarkrc.cjs",
        ".remarkrc.mjs",
        ".remarkrc.yml",
        ".remarkrc.yaml",
        ".remarkignore",
    },
    settings     = {
        remark = { requireConfig = false },
    },
}

return M
