#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua foldlevel=3 foldmethod=expr:
-- luacheck: globals vim

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/ftmatrix.lua
--
--

--
-- Heuristic filetype resolution.
--

local M = {
    extension = {},
    filename  = {
        ["ignore"]         = "gitignore",
        [".chezmoiignore"] = "gitignore",
        [".assetsignore"]  = "gitignore", -- CloudFlare Worker wrangler config
    },
    pattern   = {
        [".*gnupg/.*%.conf"] = "gpg",
        [".*/hypr/.*%.conf"] = "hyprlang",

        [".*config/zsh/.*"]       = "zsh",
        [".*zsh/func/[^/]*"]      = "zsh",
        [".*zsh/functions/[^/]*"] = "zsh",
    },
}

local define_dosini = function()
    local exts = {
        "conf",

        -- Systemd
        "automount",
        "device",
        "mount",
        "path",
        "scope",
        "service",
        "slice",
        "snapshot",
        "socket",
        "swap",
        "target",
        "timer",
    }

    for _, ext in ipairs(exts) do
        M.extension[ext] = "dosini"
    end
end

M.setup = function()
    define_dosini()
    vim.filetype.add({
        extension = M.extension,
        filename  = M.filename,
        pattern   = M.pattern,
    })
end

return M
