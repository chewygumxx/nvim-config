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
---@type mini.test
local MiniTest = require("mini.test")
local eq       = MiniTest.expect.equality

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

    ---@type vim.lsp.Config
    local defaults

    before_each(function()
        original = vim.diagnostic.config()
        defaults = vim.deepcopy(vim.lsp.config["*"]) or {}
    end)

    after_each(function()
        vim.diagnostic.config(original)
        vim.api.nvim_create_augroup("UtilLspAttach", { clear = true })
        vim.api.nvim_create_augroup("cgxx.lsp_named", { clear = true })
        -- Assigned rather than passed to `vim.lsp.config("*", ...)`, which
        -- deep-merges and so could never take a key back out
        vim.lsp.config["*"] = defaults
        -- `setup` enables every server, and an enabled server would start
        -- on the next buffer of its filetype in every later file
        vim.lsp.enable(lsp.servers(), false)
    end)

    it("enables exactly the servers lsp/ configures", function()
        lsp.setup()
        for _, name in ipairs(lsp.servers()) do
            eq({ name, vim.lsp.is_enabled(name) }, { name, true })
        end
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

    it("leaves the \"*\" defaults as it found them", function()
        -- Guards the restore above: `setup` writes a global that every
        -- later file's servers would otherwise inherit
        eq(vim.lsp.config["*"].capabilities, nil)
    end)
end)

describe("util.lsp.servers", function()
    it("names every file under lsp/, sorted", function()
        ---@type string[]
        local want = {}
        ---@type string[]
        local paths = vim.fn.globpath("lsp", "*.lua", true, true)
        for _, path in ipairs(paths) do
            table.insert(want, vim.fn.fnamemodify(path, ":t:r"))
        end
        table.sort(want)

        eq(#want > 0, true)
        eq(lsp.servers(), want)
    end)
end)

describe("util.lsp.node_available / js_root", function()
    ---@type string
    local root

    ---@type integer[]
    local bufs

    --- A buffer named for `path` under the fixture, never loaded.
    ---@param path string
    ---@return integer buf
    local buf_at = function(path)
        local buf = vim.fn.bufadd(vim.fs.joinpath(root, path))
        table.insert(bufs, buf)
        return buf
    end

    --- Writes an empty file, creating directories on the way.
    ---@param path string
    ---@return string full
    local touch = function(path)
        local full = vim.fs.joinpath(root, path)
        vim.fn.mkdir(vim.fs.dirname(full), "p")
        vim.fn.writefile({}, full)
        return full
    end

    before_each(function()
        root = vim.fn.tempname()
        vim.fn.mkdir(vim.fs.joinpath(root, ".git"), "p")
        bufs = {}
    end)

    after_each(function()
        for _, buf in ipairs(bufs) do
            vim.api.nvim_buf_delete(buf, { force = true })
        end
        vim.fn.delete(root, "rf")
    end)

    it("prefers a project's own node_modules binary", function()
        local exe = "cgxx-test-no-such-server"
        eq(lsp.node_available(exe, root), false)

        vim.fn.setfperm(touch("node_modules/.bin/" .. exe), "rwxr-xr-x")
        eq(lsp.node_available(exe, root), true)
    end)

    it("roots at the nearest lockfile over .git", function()
        touch("packages/app/package-lock.json")
        eq(
            lsp.js_root(buf_at("packages/app/src/a.ts")),
            vim.fs.joinpath(root, "packages/app")
        )
    end)

    it("falls back to .git without a lockfile", function()
        eq(lsp.js_root(buf_at("src/a.ts")), root)
    end)

    it("declines a Deno project", function()
        touch("deno.json")
        eq(lsp.js_root(buf_at("src/a.ts")), nil)
    end)

    it("keeps a Node package nested inside a Deno one", function()
        touch("deno.json")
        touch("web/package-lock.json")
        eq(lsp.js_root(buf_at("web/a.ts")), vim.fs.joinpath(root, "web"))
    end)
end)

describe("util.lsp.named_root", function()
    ---@type integer
    local bufnr
    ---@type string
    local root

    before_each(function()
        root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/notes", "p")
        vim.fn.writefile({}, root .. "/.moxide.toml")
        -- Not a scratch buffer: `vim.fs.root` searches from the cwd for
        -- any buffer whose 'buftype' is set
        bufnr = vim.api.nvim_create_buf(false, false)
    end)

    after_each(function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
        vim.fn.delete(root, "rf")
    end)

    it("declines a buffer with no name, and marks it", function()
        ---@type boolean
        local called = false
        lsp.named_root({ ".moxide.toml" })(bufnr, function()
            called = true
        end)
        eq(called, false)
        eq(vim.b[bufnr].cgxx_lsp_unnamed, true)
    end)

    it("roots a named buffer at the nearest marker", function()
        vim.api.nvim_buf_set_name(bufnr, root .. "/notes/a.md")
        ---@type string?
        local found
        lsp.named_root({ ".moxide.toml" })(bufnr, function(dir)
            found = dir
        end)
        eq(found, root)
    end)
end)

describe("util.lsp.attach_when_named", function()
    after_each(function()
        vim.api.nvim_del_augroup_by_name("cgxx.lsp_named")
    end)

    it("watches both ways a buffer gains a name", function()
        lsp.attach_when_named()
        ---@type string[]
        local events = {}
        for _, autocmd in ipairs(
            vim.api.nvim_get_autocmds({
                group = "cgxx.lsp_named",
            })
        ) do
            events[#events + 1] = autocmd.event
        end
        table.sort(events)
        eq(events, { "BufFilePost", "BufWritePost" })
    end)
end)
