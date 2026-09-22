#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/markdown.lua
--
--

--
-- Filetype-specific configuration for Markdown
--

local M = {}

---@type { [string]: number | string | boolean }
M.local_opts = {
    shiftwidth = 2,
    spell      = true,
}

---@type { [string]: vim.api.keyset.highlight }
local hlgroup_defs = {
    ["@markup.heading"]   = { fg = "#aaa6fa", bold = true },
    ["@markup.heading.1"] = { fg = "#7fb5ff", bold = true },
    ["@markup.heading.2"] = { fg = "#8394f6", bold = true },
    ["@markup.heading.3"] = { fg = "#8874ed", bold = true },
    ["@markup.heading.4"] = { fg = "#8d53e5", bold = true },
    ["@markup.heading.5"] = { fg = "#9233dc", bold = true },
    ["@markup.heading.6"] = { fg = "#7408cf", bold = true },
    ["@markup.list"]      = { link = "@markup.heading.markdown" },

    -- Depends on custom
    ["@markup.link.text"]    = { link = "@function.call" },
    ["@markup.link.label"]   = { link = "@property" },
    ["@markup.link.url"]     = { fg = "#6f25f6", underline = true },
    ["@markup.link.bracket"] = { fg = "#4408a4", underline = false },

    ["@punctuation.special"] = { fg = "#7408c4" },
    ["@label"]               = { link = "@punctuation.special.markdown" },
}

---@type { [string]: vim.api.keyset.highlight }
M.hlgroup_defs = {}
for hlgroup, defmap in pairs(hlgroup_defs) do
    M.hlgroup_defs[hlgroup .. ".markdown"]        = defmap
    M.hlgroup_defs[hlgroup .. ".markdown_inline"] = defmap
end

return M
