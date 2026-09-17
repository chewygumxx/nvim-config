#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lsp/remark_ls.lua
--
--

---@type vim.lsp.Config
local M = {
    root_markers = {
        ".remarkrc",
        ".remarkrc.cjs",
        ".remarkrc.js",
        ".remarkrc.json",
        ".remarkrc.mjs",
        ".remarkrc.yaml",
        ".remarkrc.yml",
        "package.json",
    },
}

return M
