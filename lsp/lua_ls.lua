#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/lua_ls.lua
--
--

---@type vim.lsp.Config
local M = {
    cmd       = { "lua-language-server" },
    filetypes = { "lua" },
    -- Any tool's config marks a root, and `.git` only where none does
    root_markers = {
        {
            ".emmyrc.json",
            ".luarc.json",
            ".luarc.jsonc",
            ".luacheckrc",
            ".luafmt.toml",
            "luafmt.toml",
            ".stylua.toml",
            "stylua.toml",
            "selene.toml",
            "selene.yml",
        },
        { ".git" },
    },
    settings     = {
        Lua = {
            codeLens = { enable = true },
            hint     = { enable = true, semicolon = "Disable" },
        },
    },
}

-- Rescan post-lazyloaded library inclusion
---@type table<integer, true>
local rescanned = {}

---@param client vim.lsp.Client
---@return nil
local nudge_library_rescan = function(client)
    if not client.root_dir or rescanned[client.id] then
        return
    end
    rescanned[client.id] = true
    vim.defer_fn(function()
        if not vim.lsp.get_client_by_id(client.id) then
            return
        end
        -- Private methods, on purpose: the public `vim.lsp.buf` pair calls
        -- these same two for every client of whichever buffer is current
        -- when this fires, and `remove_workspace_folder` notifies "is not
        -- currently part of the workspace" even on success. A Neovim bump
        -- that renames them fails here, loudly, rather than elsewhere.
        client:_remove_workspace_folder(client.root_dir)
        client:_add_workspace_folder(client.root_dir)
    end, 500)
end

---@type { [string]: vim.api.keyset.highlight }
local hlgroup_defs = {
    ["@lsp.typemod.variable.defaultLibrary.lua"] = { link = "Special" },
}

---@return nil
local highlights = function()
    for hlgroup, defmap in pairs(hlgroup_defs) do
        vim.api.nvim_set_hl(0, hlgroup, defmap)
    end
end

---@param client vim.lsp.Client
---@return nil
M.on_attach = function(client)
    nudge_library_rescan(client)
    highlights()
end

return M
