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
    settings = {
        remark = { requireConfig = false },
    },
}

return M
