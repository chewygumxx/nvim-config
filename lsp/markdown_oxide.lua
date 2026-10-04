#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/markdown_oxide.lua
--
--

--- A `root_dir` rather than `root_markers`: the server panics on a buffer
--- with no name, and that buffer would share, and so kill, the cwd's client.
--- See `util.lsp.named_root`.
---@type vim.lsp.Config
local M = {
    cmd       = { "markdown-oxide" },
    filetypes = { "markdown" },
    root_dir  = require("util.lsp").named_root({
        ".moxide.toml",
        ".git",
        "README",
        "index.md",
    }),
}

---@type lsp.ClientCapabilities
local extra_capabilities = {
    workspace = {
        didChangeWatchedFiles = {
            dynamicRegistration = true,
        },
    },
}

---@type lsp.ClientCapabilities
M.capabilities = vim.tbl_deep_extend(
    "force",
    require("util.lsp").capabilities(),
    extra_capabilities
)

--- `:LspToday`, `:LspTomorrow` and `:LspYesterday`, each opening that
--- day's note through the server's own `jump` command.
---@param client vim.lsp.Client
---@param buf    integer
---@return nil
M.on_attach = function(client, buf)
    for _, day in ipairs({ "today", "tomorrow", "yesterday" }) do
        local name = "Lsp" .. day:sub(1, 1):upper() .. day:sub(2)
        vim.api.nvim_buf_create_user_command(buf, name, function()
            client:exec_cmd({
                title     = "Markdown-Oxide-" .. day,
                command   = "jump",
                arguments = { day },
            }, { bufnr = buf })
        end, { desc = ("Open %s's daily note"):format(day) }
        )
    end
end

return M
