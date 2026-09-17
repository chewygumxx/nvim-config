#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/home/dot_config/nvim/lsp/marksman.lua
--
--

local cgxx_mod = _G.require_guard("cgxx") or {}
local cgxx     = cgxx_mod.lsp or {}
if cgxx.markdown ~= "marksman" then
    return {}
end

---@type vim.lsp.Config
local M = {
    cmd = { "marksman", "server" },
    filetypes = { "markdown" },
    root_markers = { ".marksman.toml", ".git" },
}

-- Placeholder for the inevitable overwrites later
local hlgroup_defs = {
    ["@lsp.sample.highlight.group"] = { link = "Sample" },
}

---@return nil
local highlights = function()
    for hlgroup, defmap in pairs(hlgroup_defs) do
        vim.api.nvim_set_hl(0, hlgroup, defmap)
    end
end

M.on_attach = function()
    highlights()
end

return M
