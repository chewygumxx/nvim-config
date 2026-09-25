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
-- more specific than any/unknown.--
--
-- Usage: `nvim --headless -u scripts/minimal_init.lua
--         -l scripts/luals_untyped.lua`
--
-- This is a CI gate whose pass signal is the *absence* of output, which
-- makes every silent failure mode a false pass: a request that errored or
-- timed out, a client that never finished indexing, an empty file list
-- from the wrong working directory. So nothing here degrades to an empty
-- result. Anything that would leave a file unexamined is fatal instead,
-- and a run that ends up having seen no inlay hints at all is treated as
-- the check not having run rather than as nothing to report.
--

--- Prints msg and exits non-zero.
---
--- `print` rather than `io.stderr`, matching the rest of this script's
--- output: selene's `lua51` standard library does not model `io.stderr`'s
--- fields, so writing there is a lint error.
---@param msg string
---@return nil
local function fatal(msg)
    print(msg)
    os.exit(1)
end

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

-- An empty list would otherwise sail through as "0 untyped hints"
if #files <= 1 then
    fatal(
        "No Lua files found under " .. vim.fn.getcwd()
            .. "; run this from the repository root"
    )
end

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
    ---@type string[]
    local parts = {}
    for _, part in ipairs(label) do
        parts[#parts + 1] = part.value
    end
    return table.concat(parts)
end

---@param client vim.lsp.Client
---@param buf    integer
---@param name   string         Path, for failure messages
---@return lsp.InlayHint[]
local function request_hints(client, buf, name)
    local last_line = vim.api.nvim_buf_line_count(buf) - 1
    local last_col  = #(vim.api.nvim_buf_get_lines(buf, last_line, last_line + 1, false)[1]
        or "")

    local response, err = client:request_sync("textDocument/inlayHint", {
        textDocument = vim.lsp.util.make_text_document_params(buf),
        range = {
            start = { line = 0, character = 0 },
            ["end"] = { line = last_line, character = last_col },
        },
    }, 10000, buf
    )

    -- A timeout or a transport failure is not "this file is fully
    -- annotated"; `assert` both says so and narrows the optional away
    assert(
        response,
        string.format(
            "inlayHint request failed for %s: %s",
            name,
            err or "no response"
        )
    )
    ---@type lsp.ResponseError?
    local rpc_err = response.err
    if rpc_err then
        error(
            string.format(
                "inlayHint errored for %s: %s",
                name,
                rpc_err.message
            )
        )
    end

    ---@type lsp.InlayHint[]?
    local hints = response.result
    return hints or {}
end

---@type integer?
local client_id
local untyped = 0

--- Hints of any kind seen across the whole run: the evidence that LuaLS
--- was actually answering. Zero of them means the check never looked,
--- which must not read the same as "nothing to report".
local seen = 0

for _, file in ipairs(files) do
    local buf = vim.fn.bufadd(file)
    vim.fn.bufload(buf)
    vim.bo[buf].filetype = "lua"

    if not client_id then
        client_id     = assert(
            vim.lsp.start(client_start_opts, { bufnr = buf }),
            "failed to start lua_ls"
        )
        local started = vim.lsp.get_client_by_id(client_id)
        if not vim.wait(60000, function()
            return started ~= nil and started.initialized == true
        end, 100
        ) then
            fatal("lua_ls did not initialize within 60s")
        end

        -- LuaLS also needs to index the workspace (`.luarc.json` library
        -- paths, installed plugin types, etc.) before hints for the
        -- *first* buffer are trustworthy, and there is no client-visible
        -- "workspace indexed" event to wait on. Rather than sleep for a
        -- fixed grace period and hope, the first file is polled until it
        -- answers with at least one hint: that answer is the proof that
        -- indexing has finished, and never getting one is a failure
        -- rather than a silent pass on an unindexed workspace.
        local client = assert(started, "lua_ls client vanished")
        if not vim.wait(120000, function()
            return #request_hints(client, buf, file) > 0
        end, 500
        ) then
            fatal(
                "lua_ls returned no inlay hints for " .. file
                    .. "; the workspace never finished indexing"
            )
        end
    else
        vim.lsp.buf_attach_client(buf, client_id)
    end

    local attached = assert(
        vim.lsp.get_client_by_id(client_id),
        "lua_ls client died"
    )

    local relpath = file:sub(#vim.fn.getcwd() + 2)
    local hints   = request_hints(attached, buf, file)
    seen          = seen + #hints
    for _, hint in ipairs(hints) do
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

-- The last thing that could make a green run meaningless: hints enabled
-- but nothing ever returned, ie. a check that examined nothing at all
if seen == 0 then
    fatal(
        "No inlay hints returned for any of the " .. #files
            .. " file(s); the check did not run"
    )
end

print(
    string.format(
        "\n%d untyped hint(s) across %d file(s), from %d hint(s) examined",
        untyped,
        #files,
        seen
    )
)
os.exit(untyped > 0 and 1 or 0)
