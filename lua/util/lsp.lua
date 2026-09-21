#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/lsp.lua
--
--

--
-- Shared LSP setup: capabilities, diagnostic display, buffer-local
-- keymaps on LspAttach. Required from spec/nvim-lspconfig.lua.
--

---@module "blink.cmp"

local M = {}

--- Client capabilities advertised to every LSP server: Neovim's own
--- defaults merged with blink.cmp's completion-related capabilities.
---@return lsp.ClientCapabilities capabilities
M.capabilities = function()
    local ok, blink = pcall(require, "blink.cmp")
    if not ok then
        return vim.lsp.protocol.make_client_capabilities()
    end
    return blink.get_lsp_capabilities(nil, true)
end

--- Applies this config's global `vim.diagnostic.config()`.
---@return nil
M.diagnostic = function()
    vim.diagnostic.config({
        virtual_text = true,
        severity_sort = true,
        float = {
            border = "rounded",
            source = true,
        },
    })
end

--
-- Buffer-local LSP keymaps
-- Only meaningful once a client has attached to a buffer, so (unlike
-- keymap.lua's global keymaps) these are wired up per-buffer from
-- M.on_attach(), called from an LspAttach autocmd, not from setup().
--

--- Maps lhs to `vim.lsp.buf.declaration`, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "gD"
---@param desc? string  Default: "LSP: Goto declaration"
---@return nil
M.goto_declaration = function(buf, lhs, desc)
    lhs  = lhs or "gD"
    desc = desc or "LSP: Goto declaration"
    vim.keymap.set("n", lhs, vim.lsp.buf.declaration, {
        buffer = buf,
        desc = desc,
    })
end

--- Maps lhs to `vim.lsp.buf.definition`, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "gd"
---@param desc? string  Default: "LSP: Goto definition"
---@return nil
M.goto_definition = function(buf, lhs, desc)
    lhs  = lhs or "gd"
    desc = desc or "LSP: Goto definition"
    vim.keymap.set("n", lhs, vim.lsp.buf.definition, {
        buffer = buf,
        desc   = desc,
    })
end

--- Maps lhs to `vim.lsp.buf.implementation`, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "gi"
---@param desc? string  Default: "LSP: Goto implementation"
---@return nil
M.goto_implementation = function(buf, lhs, desc)
    lhs  = lhs or "gi"
    desc = desc or "LSP: Goto implementation"
    vim.keymap.set("n", lhs, vim.lsp.buf.implementation, {
        buffer = buf,
        desc   = desc,
    })
end

--- Maps lhs to `vim.lsp.buf.references`, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "gr"
---@param desc? string  Default: "LSP: List references"
---@return nil
M.goto_references = function(buf, lhs, desc)
    lhs  = lhs or "gr"
    desc = desc or "LSP: List references"
    vim.keymap.set("n", lhs, vim.lsp.buf.references, {
        buffer = buf,
        desc   = desc,
    })
end

--- Maps lhs to `vim.lsp.buf.type_definition`, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "gy"
---@param desc? string  Default: "LSP: Goto type definition"
---@return nil
M.goto_type_definition = function(buf, lhs, desc)
    lhs  = lhs or "gy"
    desc = desc or "LSP: Goto type definition"
    vim.keymap.set("n", lhs, vim.lsp.buf.type_definition, {
        buffer = buf,
        desc   = desc,
    })
end

--- Maps lhs to `vim.lsp.buf.hover`, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "K"
---@param desc? string  Default: "LSP: Hover documentation"
---@return nil
M.hover = function(buf, lhs, desc)
    lhs  = lhs or "K"
    desc = desc or "LSP: Hover documentation"
    vim.keymap.set("n", lhs, vim.lsp.buf.hover, { buffer = buf, desc = desc })
end

--- Maps lhs to `vim.lsp.buf.rename`, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "<leader>cr"
---@param desc? string  Default: "LSP: Rename symbol"
---@return nil
M.rename = function(buf, lhs, desc)
    lhs  = lhs or "<leader>cr"
    desc = desc or "LSP: Rename symbol"
    vim.keymap.set("n", lhs, vim.lsp.buf.rename, { buffer = buf, desc = desc })
end

--- Maps lhs to `vim.lsp.buf.code_action` (normal and visual), buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "<leader>ca"
---@param desc? string  Default: "LSP: Code action"
---@return nil
M.code_action = function(buf, lhs, desc)
    lhs  = lhs or "<leader>ca"
    desc = desc or "LSP: Code action"
    vim.keymap.set({ "n", "x" }, lhs, vim.lsp.buf.code_action, {
        buffer = buf,
        desc = desc,
    })
end

--- Maps lhs to `vim.lsp.buf.incoming_calls`, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "<leader>ci"
---@param desc? string  Default: "LSP: Incoming calls"
---@return nil
M.incoming_calls = function(buf, lhs, desc)
    lhs  = lhs or "<leader>ci"
    desc = desc or "LSP: Incoming calls"
    vim.keymap.set("n", lhs, vim.lsp.buf.incoming_calls, {
        buffer = buf,
        desc   = desc,
    })
end

--- Maps lhs to `vim.lsp.buf.outgoing_calls`, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "<leader>co"
---@param desc? string  Default: "LSP: Outgoing calls"
---@return nil
M.outgoing_calls = function(buf, lhs, desc)
    lhs  = lhs or "<leader>co"
    desc = desc or "LSP: Outgoing calls"
    vim.keymap.set("n", lhs, vim.lsp.buf.outgoing_calls, {
        buffer = buf,
        desc   = desc,
    })
end

--- Maps lhs to jump to and float the previous diagnostic, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "[d"
---@param desc? string  Default: "LSP: Previous diagnostic"
---@return nil
M.diagnostic_prev = function(buf, lhs, desc)
    lhs  = lhs or "[d"
    desc = desc or "LSP: Previous diagnostic"
    vim.keymap.set("n", lhs, function()
        vim.diagnostic.jump({
            count = -1,
            on_jump = function()
                vim.diagnostic.open_float()
            end,
        })
    end, { buffer = buf, desc = desc }
    )
end

--- Maps lhs to jump to and float the next diagnostic, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "]d"
---@param desc? string  Default: "LSP: Next diagnostic"
---@return nil
M.diagnostic_next = function(buf, lhs, desc)
    lhs  = lhs or "]d"
    desc = desc or "LSP: Next diagnostic"
    vim.keymap.set("n", lhs, function()
        vim.diagnostic.jump({
            count   = 1,
            on_jump = function()
                vim.diagnostic.open_float()
            end,
        })
    end, { buffer = buf, desc = desc }
    )
end

--- Maps lhs to `vim.diagnostic.open_float`, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "<leader>e"
---@param desc? string  Default: "LSP: Open diagnostic float"
---@return nil
M.diagnostic_open_float = function(buf, lhs, desc)
    lhs  = lhs or "<leader>e"
    desc = desc or "LSP: Open diagnostic float"
    vim.keymap.set("n", lhs, vim.diagnostic.open_float, {
        buffer = buf,
        desc   = desc,
    })
end

--- Maps lhs to fzf-lua's workspace diagnostics picker, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "<leader>eq"
---@param desc? string  Default: "LSP: Diagnostics (workspace)"
---@return nil
M.diagnostics_workspace = function(buf, lhs, desc)
    lhs  = lhs or "<leader>eq"
    desc = desc or "LSP: Diagnostics (workspace)"
    vim.keymap.set("n", lhs, function()
        require("fzf-lua").diagnostics_workspace()
    end, { buffer = buf, desc = desc }
    )
end

--- Maps lhs to fzf-lua's document diagnostics picker, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "<leader>el"
---@param desc? string  Default: "LSP: Diagnostics (document)"
---@return nil
M.diagnostics_document = function(buf, lhs, desc)
    lhs  = lhs or "<leader>el"
    desc = desc or "LSP: Diagnostics (document)"
    vim.keymap.set("n", lhs, function()
        require("fzf-lua").diagnostics_document()
    end, { buffer = buf, desc = desc }
    )
end

--- Maps lhs to fzf-lua's document symbols picker, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "<leader>ss"
---@param desc? string  Default: "LSP: Document symbols"
---@return nil
M.document_symbols = function(buf, lhs, desc)
    lhs  = lhs or "<leader>ss"
    desc = desc or "LSP: Document symbols"
    vim.keymap.set("n", lhs, function()
        require("fzf-lua").lsp_document_symbols()
    end, { buffer = buf, desc = desc }
    )
end

--- Maps lhs to fzf-lua's workspace symbols picker, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "<leader>sS"
---@param desc? string  Default: "LSP: Workspace symbols"
---@return nil
M.workspace_symbols = function(buf, lhs, desc)
    lhs  = lhs or "<leader>sS"
    desc = desc or "LSP: Workspace symbols"
    vim.keymap.set("n", lhs, function()
        require("fzf-lua").lsp_workspace_symbols()
    end, { buffer = buf, desc = desc }
    )
end

--- Popup showing the active parameter of the function being called,
--- while typing its arguments. Only wired up for clients that actually
--- advertise signatureHelpProvider, using their own trigger characters
--- rather than assuming "(" and ",".
---@param buf    integer
---@param client vim.lsp.Client
---@return nil
M.signature_help_on_type = function(buf, client)
    local triggers = vim.tbl_get(
        client.server_capabilities,
        "signatureHelpProvider",
        "triggerCharacters"
    )
    if not triggers or #triggers == 0 then
        return
    end

    ---@type integer
    local group = vim.api.nvim_create_augroup("UtilLspSignatureHelp:" .. buf, {
        clear = true,
    })
    vim.api.nvim_create_autocmd("InsertCharPre", {
        group    = group,
        buffer   = buf,
        desc     = "LSP: Signature help while typing",
        callback = function()
            if vim.tbl_contains(triggers, vim.v.char) then
                vim.schedule(vim.lsp.buf.signature_help)
            end
        end,
    })
end

--- Wires up every buffer-local LSP keymap and signature help, called from
--- an `LspAttach` autocmd.
---@param buf    integer
---@param client vim.lsp.Client
---@return nil
M.on_attach = function(buf, client)
    M.goto_declaration(buf)
    M.goto_definition(buf)
    M.goto_implementation(buf)
    M.goto_references(buf)
    M.goto_type_definition(buf)
    M.hover(buf)
    M.rename(buf)
    M.code_action(buf)
    M.incoming_calls(buf)
    M.outgoing_calls(buf)
    M.diagnostic_prev(buf)
    M.diagnostic_next(buf)
    M.diagnostic_open_float(buf)
    M.diagnostics_workspace(buf)
    M.diagnostics_document(buf)
    M.signature_help_on_type(buf, client)
    M.document_symbols(buf)
    M.workspace_symbols(buf)
end

--- Applies global diagnostic config and capabilities, and wires
--- `M.on_attach` up to `LspAttach`.
---@return nil
M.setup = function()
    M.diagnostic()

    vim.lsp.config("*", {
        capabilities = M.capabilities(),
    })

    vim.api.nvim_create_autocmd("LspAttach", {
        group    = vim.api.nvim_create_augroup(
            "UtilLspAttach",
            { clear = true }
        ),
        desc     = "Configure buffer-local LSP keymaps on client attach",
        callback = function(event)
            local client = vim.lsp.get_client_by_id(event.data.client_id)
            if not client then
                return
            end
            M.on_attach(event.buf, client)
        end,
    })
end

return M
