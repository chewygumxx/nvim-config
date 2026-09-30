#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/eslint.lua
--
--

--
-- Starts only where the repository configures eslint, by the same
-- evidence `util.biome` weighs, so eslint and Biome cannot disagree about
-- whose file it is.
--

local biome = require("util.biome")
local lsp   = require("util.lsp")

local exe = "vscode-eslint-language-server"

---@type vim.lsp.Config
local M = {
    cmd                = lsp.node_cmd(exe, { "--stdio" }),
    filetypes          = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "svelte",
        "astro",
        "htmlangular",
    },
    workspace_required = true,
    -- https://github.com/Microsoft/vscode-eslint#settings-options
    settings = {
        validate            = "on",
        useESLintClass      = false,
        experimental        = {},
        codeActionOnSave    = { enable = false, mode = "all" },
        format              = true,
        quiet               = false,
        onIgnoredFiles      = "off",
        rulesCustomizations = {},
        run                 = "onType",
        problems            = { shortenToSingleLine = false },
        -- Relative to the workspace folder
        nodePath         = "",
        workingDirectory = { mode = "auto" },
        codeAction       = {
            disableRuleComment = {
                enable   = true,
                location = "separateLine",
            },
            showDocumentation  = { enable = true },
        },
    },
}

---@param buf    integer
---@param on_dir fun(root_dir?: string)
---@return nil
M.root_dir = function(buf, on_dir)
    local root = lsp.js_root(buf)
    if root and biome.configures(biome.dir(buf), biome.eslint)
        and lsp.node_available(exe, root) then
        on_dir(root)
    end
end

--- `workspaceFolder` is a VS Code notion the server still reads: it
--- bounds how far up it looks for an eslint config.
---@param _      lsp.InitializeParams
---@param config vim.lsp.ClientConfig
---@return nil
M.before_init = function(_, config)
    local root = config.root_dir
    if not root then
        return
    end
    lsp.merge_settings(config, {
        workspaceFolder = {
            uri  = vim.uri_from_fname(root),
            name = vim.fs.basename(root),
        },
    })
end

--- Requests the server makes of its client, answered as VS Code would.
---@type table<string, lsp.Handler>
M.handlers = {
    ["eslint/openDoc"] = function(_, result)
        if result then
            vim.ui.open(result.url)
        end
        return {}
    end,
    -- 4 is "approved": run the project's own eslint without asking
    ["eslint/confirmESLintExecution"] = function(_, result)
        return result and 4 or nil
    end,
    ["eslint/probeFailed"] = function()
        vim.notify("eslint: probe failed", vim.log.levels.WARN)
        return {}
    end,
    ["eslint/noLibrary"] = function()
        vim.notify("eslint: unable to find the library", vim.log.levels.WARN)
        return {}
    end,
}

---@param client vim.lsp.Client
---@param buf    integer
---@return nil
M.on_attach = function(client, buf)
    vim.api.nvim_buf_create_user_command(buf, "LspEslintFixAll", function()
        client:request_sync("workspace/executeCommand", {
            command   = "eslint.applyAllFixes",
            arguments = {
                {
                    uri     = vim.uri_from_bufnr(buf),
                    version = vim.lsp.util.buf_versions[buf],
                },
            },
        }, nil, buf
        )
    end, { desc = "Apply every eslint fix to the buffer" }
    )
end

return M
