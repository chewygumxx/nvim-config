#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/marksman.lua
--
--

---@type vim.lsp.Config
local M = {
    cmd          = { "marksman", "server" },
    filetypes    = { "markdown", "markdown.mdx" },
    root_markers = { ".marksman.toml", ".git" },
}

return M
