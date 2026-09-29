#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/highlight.lua
--
--

--
-- Fundamental universal highlight group definitions
-- Initialised after treesitter and colorscheme plugins
--

local M = {}

-- Highlight Table
---@type { [string]: vim.api.keyset.highlight }
local hlgroup_defs = {
    -- Background Transparency and Anti-Eye Strain
    ["Normal"]     = { ctermbg = "none", fg = "#cad6ff", bg = "none" },
    ["Search"]     = { bold = true, fg = "#e0e8ff", bg = "#52408f" },
    ["Title"]      = { bold = true, fg = "#cad6ff" },
    ["NonText"]    = { ctermbg = "none", bg = "none" },
    ["Underlined"] = { underline = true },

    -- Match `Normal`'s transparency in floating windows (Telescope, Lazy,
    -- LSP hover/diagnostics, etc.), which otherwise keep starry's solid
    -- `NormalFloat`/`FloatBorder` background and stand out as boxes.
    ["NormalFloat"] = { ctermbg = "none", bg = "none" },
    ["FloatBorder"] = { ctermbg = "none", bg = "none" },

    -- Paired-Boundary Character
    ["MatchParen"] = { standout = true },

    --
    -- The three parts of `util.statusline`'s repository notation, ie.
    -- `~chewygumxx/nvim-config.git:main:/lua/highlight.lua`. The branch is
    -- the part that changes under you, so it is the one emphasised.
    --
    -- Foreground only, deliberately: each is drawn over whichever group the
    -- window's statusline already had, `StatusLine` or `StatusLineNC`, and
    -- naming a background here would make an inactive window's statusline
    -- carry the active one's.
    --
    ["CgxxStatuslineSlug"]   = { fg = "#8394f6" },
    ["CgxxStatuslineBranch"] = { fg = "#7fb5ff", bold = true },
    ["CgxxStatuslinePath"]   = { fg = "#cad6ff" },

    -- Define @markup Underline, Bold and Strikethrough
    ["@markup.strong"]        = { bold = true },
    ["@markup.underline"]     = { underline = true },
    ["@markup.strikethrough"] = { strikethrough = true },
}

--- Applies this module's highlight group overrides.
---@return nil
M.setup = function()
    for hlgroup, defmap in pairs(hlgroup_defs) do
        vim.api.nvim_set_hl(0, hlgroup, defmap)
    end
end

return M
