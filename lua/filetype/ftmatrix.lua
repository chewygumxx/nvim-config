#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- vim: foldlevel=3:foldmethod=expr

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/dot_config/nvim/lua/util/ftmatrix.lua
--
--

--
-- Heuristic filetype resolution.
--

local M = {}

M.setup = function()
    vim.filetype.add({
        extension = {
            zshrc = "zsh",
        },
        filename = {
            ["ignore"]         = "gitignore",
            [".chezmoiignore"] = "gitignore",
            [".assetsignore"]  = "gitignore",  -- CloudFlare Worker wrangler config
        },
        pattern = {
            [".*gnupg/.*%.conf"] = "gpg",
            [".*/hypr/.*%.conf"] = "hyprlang",
            [".*config/environment.d/.*%.conf"] = "systemd",

            [".*config/zsh/.*"]       = "zsh",
            [".*zsh/func/[^/]*"]      = "zsh",
            [".*zsh/functions/[^/]*"] = "zsh",
        },
    })
end

return M
