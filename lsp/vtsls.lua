#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/vtsls.lua
--
--

local lsp = require("util.lsp")

---@type vim.lsp.Config
local M = {
    cmd          = { "vtsls", "--stdio" },
    filetypes    = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
    },
    init_options = { hostInfo = "neovim" },
}

---@param buf    integer
---@param on_dir fun(root_dir?: string)
---@return nil
M.root_dir = function(buf, on_dir)
    local root = lsp.js_root(buf)
    if root then
        on_dir(root)
    end
end

return M
