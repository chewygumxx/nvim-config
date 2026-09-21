#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/ftmatrix.lua
--
--

--
-- Heuristic filetype resolution.
--

local M = {}

---@type vim.filetype.add.filetypes
M.filetypes = {
    extension = {
        conf      = "dosini",
        automount = "dosini",
        device    = "dosini",
        mount     = "dosini",
        path      = "dosini",
        scope     = "dosini",
        service   = "dosini",
        slice     = "dosini",
        snapshot  = "dosini",
        socket    = "dosini",
        swap      = "dosini",
        target    = "dosini",
        timer     = "dosini",
    },

    filename = {
        ["ignore"]         = "gitignore",
        [".chezmoiignore"] = "gitignore",
        [".assetsignore"]  = "gitignore", -- CloudFlare Worker wrangler config
    },

    pattern = {
        [".*gnupg/.*%.conf"] = "gpg",
        [".*/hypr/.*%.conf"] = "hyprlang",

        [".*config/zsh/.*"]       = "zsh",
        [".*zsh/func/[^/]*"]      = "zsh",
        [".*zsh/functions/[^/]*"] = "zsh",
    },
}

--- Registers this module's extension/filename/pattern filetype mappings.
---@return nil
M.setup = function()
    vim.filetype.add(M.filetypes)
end

return M
