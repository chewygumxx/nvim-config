#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

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
