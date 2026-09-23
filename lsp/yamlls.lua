#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/yamlls.lua
--
--

---@type vim.lsp.Config
local M = {
    settings = {
        yaml = {
            -- schemastore.nvim supplies the catalog instead, avoids a
            -- redundant fetch from yaml-language-server's own store.
            schemaStore = { enable = false, url = "" },
            schemas = require("schemastore") --[[@as schemastore]]
                .yaml
                .schemas(),
        },
    },
}

return M
