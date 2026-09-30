#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/sqls.lua
--
--

---@type vim.lsp.Config
local M = {
    cmd       = { "sqls" },
    filetypes = { "sql", "mysql" },
    -- sqls reads its connections from `config.yml`, so that is the root
    root_markers = { "config.yml" },
}

return M
