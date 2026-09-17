#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lsp/markdown_oxide.lua
--
--

local cgxx = _G.require_guard("cgxx").lsp or {}
if cgxx.markdown == "marksman" then
    return {}
end

---@type vim.lsp.Config
local M = {
    cmd = { "markdown_oxide" },

    filetypes = { "markdown" },
    root_markers = { ".moxide.toml", ".git", "README", "index.md" },
}

---@type lsp.ClientCapabilities
M.capabilities = vim.tbl_deep_extend(
    "force",
    _G.require_guard("util.lsp").capabilities(),
    {
        workspace = {
            didChangeWatchedFiles = {
                dynamicRegistration = true,
            },
        },
    }
)

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

---@return nil
M.on_attach = function()
    highlights()
end

return M
