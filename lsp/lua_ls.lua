#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lsp/lua_ls.lua
--
--


-- Rescan post-lazyloaded library inclusion
local rescanned = {} ---@type table<integer, true>

---@param client vim.lsp.Client
local nudge_library_rescan = function(client)
    if not client.root_dir or rescanned[client.id] then
        return
    end
    rescanned[client.id] = true
    vim.defer_fn(function()
        if not vim.lsp.get_client_by_id(client.id) then
            return
        end
        client:_remove_workspace_folder(client.root_dir)
        client:_add_workspace_folder(client.root_dir)
    end, 500)
end

---@type vim.lsp.Config
local M = {
    settings = {
        Lua = {
            workspace = {
                checkThirdParty = false,
            },
        },
    },
    on_attach = function(client)
        nudge_library_rescan(client)
    end,
}

return M
