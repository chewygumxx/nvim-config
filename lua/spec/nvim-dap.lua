#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/nvim-dap.lua
--
--

--
-- Breakpoints, stepping, and the REPL. Python and bash adapters come
-- from mason-nvim-dap.nvim's built-in handlers; JS/TS has none, so its
-- pwa-node adapter is wired up here by hand.
-- https://github.com/mfussenegger/nvim-dap
--

---@module "lazy"

---@type LazyPluginSpec
local M = {
    "mfussenegger/nvim-dap",
    keys = {
        {
            "<leader>db",
            function()
                require("dap").toggle_breakpoint()
            end,
            desc = "DAP: Toggle breakpoint",
        },
        {
            "<leader>dc",
            function()
                require("dap").continue()
            end,
            desc = "DAP: Continue",
        },
        {
            "<leader>do",
            function()
                require("dap").step_over()
            end,
            desc = "DAP: Step over",
        },
        {
            "<leader>di",
            function()
                require("dap").step_into()
            end,
            desc = "DAP: Step into",
        },
        {
            "<leader>dO",
            function()
                require("dap").step_out()
            end,
            desc = "DAP: Step out",
        },
        {
            "<leader>dt",
            function()
                require("dap").terminate()
            end,
            desc = "DAP: Terminate",
        },
        {
            "<leader>dr",
            function()
                require("dap")
                    .repl
                    .toggle()
            end,
            desc = "DAP: Toggle REPL",
        },
    },
}

M.config = function()
    local dap = require("dap")

    -- mason-nvim-dap.nvim has no working JS/TS handler ("node2" is the
    -- deprecated vscode-node-debug2 adapter; its "js" mapping has no
    -- handler file), so js-debug-adapter is wired up by hand here. This
    -- path has broken across js-debug-adapter version bumps before (its
    -- internal build layout isn't stable); check here first if JS/TS
    -- debugging stops working after a mason tool update.
    dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
            command = "node",
            args = {
                vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter"
                    .. "/js-debug/src/dapDebugServer.js",
                "${port}",
            },
        },
    }
    for _, ft in ipairs({
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
    }) do
        dap.configurations[ft] = {
            {
                type = "pwa-node",
                request = "launch",
                name = "Launch file",
                program = "${file}",
                cwd = "${workspaceFolder}",
            },
            {
                type = "pwa-node",
                request = "attach",
                name = "Attach to process",
                processId = require("dap.utils").pick_process,
                cwd = "${workspaceFolder}",
            },
        }
    end
end

return M
