#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/scripts/luals_untyped.lua
--
--

--
-- Prints every location where `lua-language-server` can't infer anything
-- more specific than `any`/`unknown`, as a stand-in for "not annotated":
-- LuaLS has no diagnostic for missing LuaCATS, only for annotations that
-- exist and disagree with usage (`--check`, already run in
-- `.husky/pre-commit`). Its `Lua.hint.paramType`/`returnType` inlay hints
-- are otherwise editor-only (`textDocument/inlayHint`); this asks the
-- same server for the same hints over every tracked `.lua` file and
-- prints the ones whose resolved type is `any`/`unknown`, so the result
-- is greppable/CI-able instead of something you have to eyeball per
-- buffer.
--
-- Usage: `nvim --headless -u scripts/minimal_init.lua
--         -l scripts/luals_untyped.lua`
--
-- False positives: a few declarations in this repo (e.g.
-- `init.lua`'s `_G.require_guard`) are deliberately typed `unknown`/
-- `any` rather than left bare; this can't tell "annotated as any" from
-- "not annotated, inferred as any" apart; read the flagged line.
--

---@type string[]
local files = {}
vim.list_extend(
    files,
    vim.fn.globpath(vim.fn.getcwd(), "lua/**/*.lua", false, true)
)
vim.list_extend(
    files,
    vim.fn.globpath(vim.fn.getcwd(), "lsp/*.lua", false, true)
)
vim.list_extend(files, { vim.fn.getcwd() .. "/init.lua" })
table.sort(files)

---@type vim.lsp.ClientConfig
local client_start_opts = {
    name = "lua_ls",
    cmd = { "lua-language-server" },
    root_dir = vim.fn.getcwd(),
    settings = {
        Lua = {
            hint = {
                enable = true,
                paramType = true,
                returnType = true,
                setType = true,
            },
        },
    },
}

---@param label string | lsp.InlayHintLabelPart[]
---@return string
local function hint_text(label)
    if type(label) == "string" then
        return label
    end
    local parts = {}
    for _, part in ipairs(label) do
        parts[#parts + 1] = part.value
    end
    return table.concat(parts)
end

---@param client vim.lsp.Client
---@param buf    integer
---@return lsp.InlayHint[]
local function request_hints(client, buf)
    local last_line = vim.api.nvim_buf_line_count(buf) - 1
    local last_col  = #(vim.api.nvim_buf_get_lines(buf, last_line, last_line + 1, false)[1]
        or "")

    local response = client:request_sync("textDocument/inlayHint", {
        textDocument = vim.lsp.util.make_text_document_params(buf),
        range = {
            start = { line = 0, character = 0 },
            ["end"] = { line = last_line, character = last_col },
        },
    }, 10000, buf
    )

    return (response and response.result) or {}
end

---@type integer?
local client_id
local untyped = 0

for _, file in ipairs(files) do
    local buf = vim.fn.bufadd(file)
    vim.fn.bufload(buf)
    vim.bo[buf].filetype = "lua"

    if not client_id then
        client_id = vim.lsp.start(client_start_opts, { bufnr = buf })
        if not client_id then
            print("Failed to start lua_ls")
            os.exit(1)
        end
        local client = vim.lsp.get_client_by_id(client_id)
        -- LuaLS needs time to index the workspace (`.luarc.json` library
        -- paths, installed plugin types, etc.) before hints for the
        -- *first* buffer are trustworthy; there is no client-visible
        -- "workspace indexed" event to wait on instead, so this is a
        -- fixed grace period rather than a real synchronisation point.
        vim.wait(
            60000,
            function() return client ~= nil and client.initialized == true end,
            100
        )
        vim.wait(5000)
    else
        vim.lsp.buf_attach_client(buf, client_id)
    end

    local client = vim.lsp.get_client_by_id(client_id)
    if not client then
        print("lua_ls client died")
        os.exit(1)
    end

    local relpath = file:sub(#vim.fn.getcwd() + 2)
    for _, hint in ipairs(request_hints(client, buf)) do
        -- kind 1 = Type (paramType/returnType/setType); 2 = Parameter
        -- (paramName), irrelevant here.
        local text = hint_text(hint.label)
        if hint.kind == 1
            and (text:find("%f[%a]any%f[%A]")
                or text:find("%f[%a]unknown%f[%A]")) then
            untyped = untyped + 1
            print(
                string.format(
                    "%s:%d:%d:%s",
                    relpath,
                    hint.position.line + 1,
                    hint.position.character + 1,
                    text
                )
            )
        end
    end
end

if client_id then
    local client = vim.lsp.get_client_by_id(client_id)
    if client then
        client:stop(true)
    end
end

print(string.format("\n%d untyped hint(s) across %d file(s)", untyped, #files))
os.exit(untyped > 0 and 1 or 0)
