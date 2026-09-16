#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lsp/jsonls.lua
--
--

---@type vim.lsp.Config
local M = {
    settings = {
        json = {
            schemas = require("schemastore")
                .json
                .schemas(),
            validate = { enable = true },
        },
    },
}

return M
