#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/util/lsp.lua
--
--

--
-- Shared LSP setup: capabilities, diagnostic display, buffer-local
-- keymaps on LspAttach. Required from spec/nvim-lspconfig.lua.
--

local M = {}

-- Client capabilities advertised to every LSP server: Neovim's own
-- defaults merged with blink.cmp's completion-related capabilities.
M.capabilities = function()
    local ok, blink = pcall(require, "blink.cmp")
    if not ok then
        return vim.lsp.protocol.make_client_capabilities()
    end
    return blink.get_lsp_capabilities(nil, true)
end

M.diagnostic = function()
    vim.diagnostic.config({
        virtual_text  = true,
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

M.goto_declaration = function(buf, lhs, desc)
    local lhs  = lhs  or 'gD'
    local desc = desc or "LSP: Goto declaration"
    vim.keymap.set('n', lhs, vim.lsp.buf.declaration, { buffer = buf, desc = desc })
end

M.goto_definition = function(buf, lhs, desc)
    local lhs  = lhs  or 'gd'
    local desc = desc or "LSP: Goto definition"
    vim.keymap.set('n', lhs, vim.lsp.buf.definition, { buffer = buf, desc = desc })
end

M.goto_implementation = function(buf, lhs, desc)
    local lhs  = lhs  or 'gi'
    local desc = desc or "LSP: Goto implementation"
    vim.keymap.set('n', lhs, vim.lsp.buf.implementation, { buffer = buf, desc = desc })
end

M.goto_references = function(buf, lhs, desc)
    local lhs  = lhs  or 'gr'
    local desc = desc or "LSP: List references"
    vim.keymap.set('n', lhs, vim.lsp.buf.references, { buffer = buf, desc = desc })
end

M.hover = function(buf, lhs, desc)
    local lhs  = lhs  or 'K'
    local desc = desc or "LSP: Hover documentation"
    vim.keymap.set('n', lhs, vim.lsp.buf.hover, { buffer = buf, desc = desc })
end

M.rename = function(buf, lhs, desc)
    local lhs  = lhs  or '<leader>cr'
    local desc = desc or "LSP: Rename symbol"
    vim.keymap.set('n', lhs, vim.lsp.buf.rename, { buffer = buf, desc = desc })
end

M.code_action = function(buf, lhs, desc)
    local lhs  = lhs  or '<leader>ca'
    local desc = desc or "LSP: Code action"
    vim.keymap.set({ 'n', 'x' }, lhs, vim.lsp.buf.code_action, { buffer = buf, desc = desc })
end

M.diagnostic_prev = function(buf, lhs, desc)
    local lhs  = lhs  or '[d'
    local desc = desc or "LSP: Previous diagnostic"
    vim.keymap.set('n', lhs, function()
        vim.diagnostic.jump({ count = -1, on_jump = function() vim.diagnostic.open_float() end })
    end, { buffer = buf, desc = desc })
end

M.diagnostic_next = function(buf, lhs, desc)
    local lhs  = lhs  or ']d'
    local desc = desc or "LSP: Next diagnostic"
    vim.keymap.set('n', lhs, function()
        vim.diagnostic.jump({ count = 1, on_jump = function() vim.diagnostic.open_float() end })
    end, { buffer = buf, desc = desc })
end

M.diagnostic_open_float = function(buf, lhs, desc)
    local lhs  = lhs  or '<leader>e'
    local desc = desc or "LSP: Open diagnostic float"
    vim.keymap.set('n', lhs, vim.diagnostic.open_float, { buffer = buf, desc = desc })
end

M.on_attach = function(buf)
    M.goto_declaration(buf)
    M.goto_definition(buf)
    M.goto_implementation(buf)
    M.goto_references(buf)
    M.hover(buf)
    M.rename(buf)
    M.code_action(buf)
    M.diagnostic_prev(buf)
    M.diagnostic_next(buf)
    M.diagnostic_open_float(buf)
end

M.setup = function()
    M.diagnostic()

    vim.lsp.config('*', {
        capabilities = M.capabilities(),
    })

    vim.api.nvim_create_autocmd('LspAttach', {
        group    = vim.api.nvim_create_augroup('UtilLspAttach', { clear = true }),
        desc     = "Configure buffer-local LSP keymaps on client attach",
        callback = function(event)
            M.on_attach(event.buf)
        end,
    })
end

return M
