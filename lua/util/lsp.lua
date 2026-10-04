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
-- keymaps on LspAttach, and enabling every server `lsp/` configures.
-- Called from `init.lua`.
--
-- There is no `nvim-lspconfig` underneath: each `lsp/<name>.lua` is the
-- whole configuration for its server, so the pieces several of them need
-- live here rather than in any one of them.
--

---@module "blink.cmp"

local M = {}

--- This repository's root, found from this file rather than from
--- `stdpath("config")`, which is a different checkout under the test
--- runner and on a machine that deploys `~/.config/nvim` separately.
---@type string
local repo = vim.fs.dirname(
    vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
)

--- The servers `lsp/` configures, by filename, sorted. This directory and
--- nothing else decides what `M.setup` enables.
---@return string[] names
M.servers = function()
    ---@type string[]
    local names = {}
    for name, kind in vim.fs.dir(vim.fs.joinpath(repo, "lsp")) do
        if kind == "file" and name:match("%.lua$") then
            table.insert(names, (name:gsub("%.lua$", "")))
        end
    end
    table.sort(names)
    return names
end

--- The `node_modules/.bin/<exe>` under `root`, if `root` has one.
---@param exe   string
---@param root? string
---@return string? path
local local_bin = function(exe, root)
    if not root then
        return nil
    end
    local bin  = vim.fs.joinpath(root, "node_modules")
    local path = vim.fs.joinpath(bin, ".bin", exe)
    return vim.fn.executable(path) == 1 and path or nil
end

--- Whether `M.node_cmd(exe, ...)` would find a binary for `root`. A server
--- whose `cmd` is a function has to ask this from its `root_dir`, since
--- Neovim only checks that a *table* `cmd` is executable, and a function
--- that cannot start one raises an error on every buffer it matches.
---@param exe   string
---@param root? string
---@return boolean
M.node_available = function(exe, root)
    return local_bin(exe, root) ~= nil or vim.fn.executable(exe) == 1
end

--- A `cmd` for a server published on npm: the project's own
--- `node_modules/.bin/<exe>` when the root has one, so the version the
--- project pins wins, and `<exe>` from `PATH` otherwise. Pair it with
--- `M.node_available` in the server's `root_dir`.
---@param exe  string
---@param args string[]
---@return fun(dispatchers: vim.lsp.rpc.Dispatchers, config: vim.lsp.ClientConfig): vim.lsp.rpc.PublicClient
M.node_cmd = function(exe, args)
    return function(dispatchers, config)
        ---@type string[]
        local argv = { local_bin(exe, config and config.root_dir) or exe }
        vim.list_extend(argv, args)
        return vim.lsp.rpc.start(argv, dispatchers)
    end
end

--- Deep-merges `extra` over the `settings` of a client or its config. A
--- server that learns a setting only once it knows its root has to write
--- it this late, and `before_init` and a live client both hold it here.
---@param holder { settings?: table }
---@param extra  table
---@return nil
M.merge_settings = function(holder, extra)
    holder.settings = vim.tbl_deep_extend("force", holder.settings or {}, extra)
end

--- Package-manager lockfiles, which mark a JavaScript project root.
---@type string[]
M.js_lockfiles = {
    "package-lock.json",
    "yarn.lock",
    "pnpm-lock.yaml",
    "bun.lockb",
    "bun.lock",
}

--- The root a JavaScript server should start from: the nearest lockfile,
--- then `.git`, then the working directory, so one server covers a whole
--- monorepo rather than one per package. Nil for a Deno project whose
--- `deno.json` or `deno.lock` is at least as close as any lockfile, since
--- Node tooling has nothing to say about one.
---@param buf integer
---@return string? root
M.js_root = function(buf)
    local project = vim.fs.root(buf, { M.js_lockfiles, { ".git" } })
    local deno    = vim.fs.root(buf, { "deno.json", "deno.jsonc", "deno.lock" })
    if deno and (not project or #deno >= #project) then
        return nil
    end
    return project or vim.fn.getcwd()
end

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
        buf = buf,
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
        buf  = buf,
        desc = desc,
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
        buf  = buf,
        desc = desc,
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
        buf  = buf,
        desc = desc,
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
        buf  = buf,
        desc = desc,
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
    vim.keymap.set("n", lhs, vim.lsp.buf.hover, { buf = buf, desc = desc })
end

--- Maps lhs to `vim.lsp.buf.rename`, buffer-local.
---@param buf   integer
---@param lhs?  string  Default: "<leader>cr"
---@param desc? string  Default: "LSP: Rename symbol"
---@return nil
M.rename = function(buf, lhs, desc)
    lhs  = lhs or "<leader>cr"
    desc = desc or "LSP: Rename symbol"
    vim.keymap.set("n", lhs, vim.lsp.buf.rename, { buf = buf, desc = desc })
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
        buf = buf,
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
        buf  = buf,
        desc = desc,
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
        buf  = buf,
        desc = desc,
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
    end, { buf = buf, desc = desc }
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
    end, { buf = buf, desc = desc }
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
        buf  = buf,
        desc = desc,
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
        ---@type fzf-lua
        local fzf = require("fzf-lua")
        fzf.diagnostics_workspace()
    end, { buf = buf, desc = desc }
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
        ---@type fzf-lua
        local fzf = require("fzf-lua")
        fzf.diagnostics_document()
    end, { buf = buf, desc = desc }
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
        ---@type fzf-lua
        local fzf = require("fzf-lua")
        fzf.lsp_document_symbols()
    end, { buf = buf, desc = desc }
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
        ---@type fzf-lua
        local fzf = require("fzf-lua")
        fzf.lsp_workspace_symbols()
    end, { buf = buf, desc = desc }
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
    local group = vim.api.nvim_create_augroup(
        string.format("UtilLspSignatureHelp:%d:%d", buf, client.id),
        { clear = true }
    )
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

--- A `root_dir` that declines a buffer with no name, and otherwise roots it
--- at the nearest of markers as `root_markers` would.
---
--- For a server that cannot open an unnamed buffer at all: markdown-oxide
--- panics on one ("file should have file stem"), and since such a buffer
--- roots at the cwd it shares that client with every named file there,
--- so the one panic takes the server down for all of them. The buffer is
--- marked instead, and `M.attach_when_named` attaches it once it has a
--- name to give.
---@param markers string[]
---@return fun(buf: integer, on_dir: fun(root_dir?: string)) root_dir
M.named_root = function(markers)
    return function(buf, on_dir)
        if vim.api.nvim_buf_get_name(buf) == "" then
            vim.b[buf].cgxx_lsp_unnamed = true
            return
        end
        on_dir(vim.fs.root(buf, markers))
    end
end

--- Registers the autocmd that offers a buffer `M.named_root` declined to
--- every enabled server again, once it has been given a name.
---
--- `:write {file}` names a buffer without firing `BufFilePost`, which only
--- `:file` and `:saveas` do, so both events are watched. Only Neovim's own
--- `nvim.lsp.enable` group is re-run, rather than the whole of `FileType`,
--- which would also re-apply every filetype module.
---@return nil
M.attach_when_named = function()
    vim.api.nvim_create_autocmd({ "BufFilePost", "BufWritePost" }, {
        group    = vim.api.nvim_create_augroup("cgxx.lsp_named", {
            clear = true,
        }),
        desc     = "Attach LSP to a buffer that has just been given a name",
        callback = function(event)
            if not vim.b[event.buf].cgxx_lsp_unnamed
                or vim.api.nvim_buf_get_name(event.buf) == "" then
                return
            end
            vim.b[event.buf].cgxx_lsp_unnamed = nil
            pcall(vim.api.nvim_exec_autocmds, "FileType", {
                group  = "nvim.lsp.enable",
                buffer = event.buf,
            })
        end,
    })
end

--- Applies global diagnostic config and capabilities, wires `M.on_attach`
--- up to `LspAttach`, and enables every server `lsp/` configures.
---
--- Enabling is done here rather than by mason-lspconfig's
--- `automatic_enable`, which only reaches what Mason installed and so
--- enabled nothing under Termux, where mason is condemned. A server whose
--- binary is absent costs a line in the LSP log and nothing else.
---@return nil
M.setup = function()
    M.diagnostic()

    vim.lsp.config("*", {
        capabilities = M.capabilities(),
    })
    vim.lsp.enable(M.servers())

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

    M.attach_when_named()
end

return M
