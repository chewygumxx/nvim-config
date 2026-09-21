#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/tombi.lua
--
--

---@type vim.lsp.Config
local M = {}

---@type { [string]: vim.api.keyset.highlight }
local hlgroup_defs = {
    ["@lsp.type.key.toml"] = { link = "@property" },
    ["@lsp.type.table.toml"] = { link = "@property" },
}

---@return nil
local highlight = function()
    for hlgroup, defmap in pairs(hlgroup_defs) do
        vim.api.nvim_set_hl(0, hlgroup, defmap)
    end
end

---@return nil
M.on_attach = function()
    highlight()
end

return M
