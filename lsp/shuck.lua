#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/shuck.lua
--
--

---@type vim.lsp.Config
local M = {
    -- shuck's own default filetypes also cover bash/sh, but bashls
    -- already owns those here; scope shuck to zsh, the one dialect
    -- bashls doesn't support.
    filetypes = { "zsh" },
}

return M
