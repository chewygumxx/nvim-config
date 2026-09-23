#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/nvim-dap-ui.lua
--
--

--
-- Sidebar/REPL UI for nvim-dap: opens on session start, closes on exit.
-- https://github.com/rcarriga/nvim-dap-ui
--

---@module "lazy"

---@type LazyPluginSpec
local M = {
    "rcarriga/nvim-dap-ui",
    dependencies = {
        "mfussenegger/nvim-dap",
        "nvim-neotest/nvim-nio",
    },
    keys = {
        {
            "<leader>du",
            function()
                require("dapui").toggle()
            end,
            desc = "DAP: Toggle UI",
        },
    },
}

M.config = function()
    local dap, dapui = require("dap"), require("dapui")
    dapui.setup()

    dap.listeners.before.attach.dapui_config           = function()
        dapui.open()
    end
    dap.listeners.before.launch.dapui_config           = function()
        dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config     = function()
        dapui.close()
    end
end

return M
