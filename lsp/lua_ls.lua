#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lsp/lua_ls.lua
--
--

-- Merged (deep) with nvim-lspconfig's own bundled lsp/lua_ls.lua (cmd,
-- filetypes, root_markers, settings.Lua.codeLens/hint) via Neovim's
-- runtimepath-based config merge; only the delta needed here goes in
-- this file. checkThirdParty is off because lazydev.nvim (see
-- spec/lazydev.nvim.lua) already supplies vim global / runtime library
-- types, so lua_ls's own third-party-library popup would be redundant
-- noise every time this config, or any other Neovim plugin repo (e.g.
-- ~/dev/header-metadata.nvim), is opened.

---@type vim.lsp.Config
local M = {
    settings = {
        Lua = {
            workspace = {
                checkThirdParty = false,
            },
        },
    },
}

return M
