#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/one-small-step-for-vimkind.lua
--
--

--
-- Debugs a separate, already-running Neovim instance's Lua runtime over
-- TCP (`require("osv").launch()` in the target instance, then attach
-- from here); it cannot debug the Neovim you're editing in.
-- https://github.com/jbyuki/one-small-step-for-vimkind
--

---@module "lazy"

---@type LazyPluginSpec
local M = {
    "jbyuki/one-small-step-for-vimkind",
    ft           = "lua",
    dependencies = { "mfussenegger/nvim-dap" },
}

M.config = function()
    local dap = require("dap") --[[@as dap]]

    dap.adapters.nlua = function(callback, config)
        callback({
            type = "server",
            host = config.host or "127.0.0.1",
            port = config.port or 8086,
        })
    end
    -- Append rather than assign: nvim-dap.lua also populates
    -- dap.configurations.lua (local-lua-debugger-vscode), and lazy-load
    -- order between the two (ft="lua" here, keys-triggered there) isn't
    -- guaranteed.
    dap.configurations.lua = dap.configurations.lua or {}
    vim.list_extend(dap.configurations.lua, {
        {
            type = "nlua",
            request = "attach",
            name = "Attach to running Neovim instance",
        },
    })
end

return M
