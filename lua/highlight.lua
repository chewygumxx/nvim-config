#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/highlight.lua
--
--

--
-- Fundamental universal highlight group definitions
-- Initialised after treesitter and colorscheme plugins
--

local M = {}

-- Highlight Table
local hlgroup_defs = {
    -- Background Transparency and Anti-Eye Strain
    ["Normal"]     = { ctermbg   = "none",    fg = "#cad6ff", bg = "none",   },
    ["Search"]     = { bold      = true,      fg = "#e0e8ff", bg = "#52408f" },
    ["Title"]      = { bold      = true,      fg = "#cad6ff" },
    ["NonText"]    = { ctermbg   = "none",    bg = "none"    },
    ["Underlined"] = { underline = true },

    -- Paired-Boundary Character
    ["MatchParen"] = { standout = true },

    -- Define @markup Underline, Bold and Strikethrough
    ["@markup.strong"]        = { bold          = true },
    ["@markup.underline"]     = { underline     = true },
    ["@markup.strikethrough"] = { strikethrough = true },
}

M.setup = function()
    for hlgroup, defmap in pairs(hlgroup_defs) do
        vim.api.nvim_set_hl(0, hlgroup, defmap)
    end
end

return M
