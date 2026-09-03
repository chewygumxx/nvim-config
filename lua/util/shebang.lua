#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/util/shebang.lua
--
--

--
-- Helper functions for shebang resolution
--

local M = {}

local source_dirs = {
    "~/doc/synexus/.zsh",

    "~/.config/hypr",
    "~/.config/nvim/lua",
    "~/.config/luarocks",
    "~/.config/wezterm",
    "~/.config/yay",
    "~/.config/yazi",
    "~/.config/zsh",

    "~/.local/share/hyprland",
    "~/.local/share/lua",
    "~/.local/share/luarocks",
    "~/.local/share/yazi/plugins",
    "~/.local/share/nvim",

    "~/.local/share/chezmoi/dot_config",
    "~/.local/share/chezmoi/dot_local/share",
}

local filetype_shebangs = {
    sh     = "#!/bin/sh",
    bash   = "#!/usr/bin/env bash",
    just   = "#!/usr/bin/env -S just --working-directory . --justfile",
    lua    = "#!/usr/bin/env lua",
    python = "#!/usr/bin/env python3",
    zsh    = "#!/usr/bin/env zsh",
}

M.get = function(file, buf, opt)
    local file = file or vim.fn.expand("%")
    local buf  = buf or 0
    local opt  = opt or {}
    local ft   = opt.ft  or vim.bo[buf].filetype

    local path = vim.fn.fnamemodify(file, ":~:h")
    for _,dir in ipairs(source_dirs) do
        if path:find(dir .. '/', 1, true) == 1 then
            return "#!/bin/false"
        end
    end

    return filetype_shebangs[ft]
end

return M

