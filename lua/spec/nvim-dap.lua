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
-- from mason-nvim-dap.nvim's built-in handlers, which already append to
-- dap.configurations via vim.list_extend(); the extra configs added here
-- append the same way, so load order against mason-nvim-dap.nvim doesn't
-- matter. JS/TS and Lua's local-lua-debugger-vscode have no mason-nvim-dap
-- handler at all, so their adapters are wired up here by hand.
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
    -- vscode-js-debug is a single multi-session server: registering more
    -- request types against the same dapDebugServer.js just tells nvim-dap
    -- which `type` to open the session as, no separate adapter process.
    dap.adapters["pwa-chrome"] = dap.adapters["pwa-node"]

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
            {
                type = "pwa-node",
                request = "launch",
                name = "Debug Jest tests",
                cwd = "${workspaceFolder}",
                program = "${workspaceFolder}/node_modules/.bin/jest",
                args = { "--runInBand" },
                console = "integratedTerminal",
                internalConsoleOptions = "neverOpen",
            },
            {
                type = "pwa-chrome",
                request = "launch",
                name = "Launch Chrome against localhost",
                url = "http://localhost:3000",
                webRoot = "${workspaceFolder}",
            },
        }
    end

    -- mason-nvim-dap.nvim's own "Python: Launch file" config covers the
    -- common case; this adds attaching to a script already running under
    -- `python -m debugpy --listen <port> script.py`.
    dap.configurations.python = dap.configurations.python or {}
    vim.list_extend(dap.configurations.python, {
        {
            type = "python",
            request = "attach",
            name = "Attach remote",
            connect = {
                host = function()
                    return vim.fn.input("Host: ", "127.0.0.1")
                end,
                port = function()
                    return tonumber(vim.fn.input("Port: ", "5678"))
                end,
            },
        },
    })

    -- one-small-step-for-vimkind covers attaching to a separate, already
    -- running Neovim instance; this covers standalone Lua scripts, which
    -- that adapter cannot debug.
    local local_lua_dbg_root  = vim.fs.joinpath(
        vim.fn.stdpath("data"),
        "mason",
        "packages",
        "local-lua-debugger-vscode"
    )
    dap.adapters["local-lua"] = {
        type = "executable",
        command = "node",
        args = {
            vim.fs.joinpath(local_lua_dbg_root, "extension", "debugAdapter.js"),
        },
        enrich_config = function(config, on_config)
            if config.extensionPath then
                on_config(config)
                return
            end
            local enriched         = vim.deepcopy(config)
            enriched.extensionPath = local_lua_dbg_root .. "/"
            on_config(enriched)
        end,
    }
    dap.configurations.lua    = dap.configurations.lua or {}
    vim.list_extend(dap.configurations.lua, {
        {
            type = "local-lua",
            request = "launch",
            name = "Launch file (local-lua-dbg)",
            cwd = "${workspaceFolder}",
            program = { lua = "lua", file = "${file}" },
            args = {},
        },
    })
end

return M
