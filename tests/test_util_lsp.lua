#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_lsp.lua
--
--

--
-- `util.lsp` is what every `lsp/<name>.lua` leans on, so that a
-- per-server file only has to carry what is genuinely server-specific.
-- None of it needs a running language server: the keymaps are ordinary
-- buffer-local mappings, and the one place a client is needed takes an
-- ordinary table, so a stand-in with the capabilities under test is
-- enough.
--

local lsp = require("util.lsp")
local eq  = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

--- Every buffer-local mapping `M.on_attach` is expected to make, by the
--- description it carries. The descriptions are what which-key and
--- `:map` show, so they are as much the contract as the keys are.
---@type table<string, string>
local mapped = {
    gD             = "LSP: Goto declaration",
    gd             = "LSP: Goto definition",
    gi             = "LSP: Goto implementation",
    gr             = "LSP: List references",
    gy             = "LSP: Goto type definition",
    K              = "LSP: Hover documentation",
    ["<leader>cr"] = "LSP: Rename symbol",
    ["<leader>ca"] = "LSP: Code action",
    ["<leader>ci"] = "LSP: Incoming calls",
    ["<leader>co"] = "LSP: Outgoing calls",
    ["[d"]         = "LSP: Previous diagnostic",
    ["]d"]         = "LSP: Next diagnostic",
    ["<leader>e"]  = "LSP: Open diagnostic float",
    ["<leader>eq"] = "LSP: Diagnostics (workspace)",
    ["<leader>el"] = "LSP: Diagnostics (document)",
    ["<leader>ss"] = "LSP: Document symbols",
    ["<leader>sS"] = "LSP: Workspace symbols",
}

--- A stand-in `vim.lsp.Client`, carrying only what `M.on_attach` reads.
---@param triggers? string[] signatureHelp trigger characters, if any
---@return table client
local client_with = function(triggers)
    return {
        id = 1,
        name = "test_ls",
        server_capabilities = triggers
            and {
                signatureHelpProvider = { triggerCharacters = triggers },
            }
            or {},
    }
end

describe("util.lsp.capabilities", function()
    it("falls back to Neovim's own capabilities without blink.cmp", function()
        -- blink.cmp is not on this suite's runtimepath, which is the
        -- fallback branch: a missing completion plugin must not take
        -- every language server down with it
        eq(lsp.capabilities(), vim.lsp.protocol.make_client_capabilities())
    end)
end)

describe("util.lsp.diagnostic", function()
    ---@type vim.diagnostic.Opts?
    local original

    before_each(function()
        original = vim.diagnostic.config()
    end)
    after_each(function()
        vim.diagnostic.config(original)
    end)

    it("applies this config's diagnostic display", function()
        lsp.diagnostic()

        -- `assert` rather than an annotation: `vim.diagnostic.config()`
        -- is declared as returning an optional, and this both narrows it
        -- and fails the case if it ever answers nothing
        local applied = assert(vim.diagnostic.config())
        eq(applied.virtual_text, true)
        eq(applied.severity_sort, true)
        eq(applied.float, { border = "rounded", source = true })
    end)
end)

describe("util.lsp.on_attach", function()
    ---@type integer
    local bufnr

    before_each(function()
        bufnr = vim.api.nvim_create_buf(false, true)
    end)
    after_each(function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    --- The description of bufnr's buffer-local normal-mode mapping for
    --- lhs, or nil when there is none.
    ---
    --- `nvim_buf_get_keymap` reports the resolved notation, so "<leader>"
    --- comes back expanded and the lookup has to expand it too.
    ---@param lhs string
    ---@return string? desc
    local desc_of = function(lhs)
        local wanted = vim.keycode(
            lhs:gsub("<leader>", vim.g.mapleader or "\\")
        )
        for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "n")) do
            if map.lhs == wanted then
                return map.desc
            end
        end
        return nil
    end

    it("maps every documented key, buffer-local", function()
        lsp.on_attach(bufnr, client_with())

        for lhs, desc in pairs(mapped) do
            eq({ lhs, desc_of(lhs) }, { lhs, desc })
        end
    end)

    it("leaves other buffers unmapped", function()
        -- The reason these are wired from `LspAttach` rather than
        -- `keymap.lua`: "K" and "gd" have perfectly good meanings in a
        -- buffer no client has attached to
        local other = vim.api.nvim_create_buf(false, true)
        lsp.on_attach(bufnr, client_with())

        eq(#vim.api.nvim_buf_get_keymap(other, "n"), 0)
        vim.api.nvim_buf_delete(other, { force = true })
    end)
end)

describe("util.lsp.signature_help_on_type", function()
    ---@type integer
    local bufnr

    --- The name of the per-buffer, per-client augroup the module uses.
    ---@param client table
    ---@return string group
    local group_of = function(client)
        return string.format("UtilLspSignatureHelp:%d:%d", bufnr, client.id)
    end

    before_each(function()
        bufnr = vim.api.nvim_create_buf(false, true)
    end)
    after_each(function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("listens on the client's own trigger characters", function()
        local client = client_with({ "(", "," })
        lsp.signature_help_on_type(bufnr, client)

        local autocmds = vim.api.nvim_get_autocmds({
            group = group_of(client),
        })
        eq(#autocmds, 1)
        eq(autocmds[1].event, "InsertCharPre")
        eq(autocmds[1].buflocal, true)

        vim.api.nvim_del_augroup_by_name(group_of(client))
    end)

    it("registers nothing for a client without signature help", function()
        -- Assuming "(" and "," for a server that never asked for them
        -- would request signature help on every such keystroke
        local client = client_with()
        lsp.signature_help_on_type(bufnr, client)

        local ok = pcall(vim.api.nvim_get_autocmds, {
            group = group_of(client),
        })
        eq(ok, false)
    end)
end)

describe("util.lsp.setup", function()
    ---@type vim.diagnostic.Opts?
    local original

    before_each(function()
        original = vim.diagnostic.config()
    end)

    after_each(function()
        vim.diagnostic.config(original)
        vim.api.nvim_create_augroup("UtilLspAttach", { clear = true })
    end)

    it("wires on_attach up to LspAttach", function()
        lsp.setup()

        local autocmds = vim.api.nvim_get_autocmds({ group = "UtilLspAttach" })
        eq(#autocmds, 1)
        eq(autocmds[1].event, "LspAttach")
    end)

    it("advertises the capabilities to every server", function()
        -- The "*" entry is how a per-server `lsp/<name>.lua` gets these
        -- without repeating them
        lsp.setup()
        eq(vim.lsp.config["*"].capabilities ~= nil, true)
    end)
end)
