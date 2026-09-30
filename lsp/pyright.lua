#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/pyright.lua
--
--

local lsp = require("util.lsp")

---@type vim.lsp.Config
local M = {
    cmd          = { "pyright-langserver", "--stdio" },
    filetypes    = { "python" },
    root_markers = {
        "pyrightconfig.json",
        "pyproject.toml",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "Pipfile",
        ".git",
    },
    settings     = {
        -- ruff reports the same hints pyright tags as unused/unreachable
        pyright = { disableTaggedHints = true },
        python  = {
            analysis = {
                -- ruff already covers linting/import-sorting, so
                -- pyright's job here is purely type analysis; opt into a
                -- level that surfaces real bugs (Optional/union misuse,
                -- etc.) rather than mirroring ruff's own checks.
                typeCheckingMode       = "standard",
                autoImportCompletions  = true,
                autoSearchPaths        = true,
                useLibraryCodeForTypes = true,
                diagnosticMode         = "openFilesOnly",
            },
        },
    },
}

--- Points the client at another interpreter and has the server re-read
--- its settings.
---@param client vim.lsp.Client
---@param path   string
---@return nil
local set_python_path = function(client, path)
    lsp.merge_settings(client, {
        python = { pythonPath = path },
    })
    client:notify("workspace/didChangeConfiguration", { settings = nil })
end

--- Sorts and prunes imports through pyright's `organizeimports`. A
--- request rather than `client:exec_cmd`, which refuses a command the
--- server does not advertise, and pyright keeps this one private.
---@param client vim.lsp.Client
---@param buf    integer
---@return nil
local organize_imports = function(client, buf)
    ---@type lsp.ExecuteCommandParams
    local params = {
        command   = "pyright.organizeimports",
        arguments = { vim.uri_from_bufnr(buf) },
    }
    client:request("workspace/executeCommand", params, nil, buf)
end

---@param client vim.lsp.Client
---@param buf    integer
---@return nil
M.on_attach = function(client, buf)
    local create = vim.api.nvim_buf_create_user_command

    create(buf, "LspPyrightOrganizeImports", function()
        organize_imports(client, buf)
    end, { desc = "Organize imports" }
    )

    create(
        buf, "LspPyrightSetPythonPath",
        function(args)
            set_python_path(client, args.args)
        end,
        {
            desc     = "Reconfigure pyright with the given python path",
            nargs    = 1,
            complete = "file",
        }
    )
end

return M
