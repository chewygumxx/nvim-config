#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

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

--- 'formatlistpat' recognises a bullet, an ordered item (`.` or `)`) and
--- either followed by a checkbox, so that `gq` and auto-wrap indent an
--- item's continuation lines past the whole marker: two columns under
--- `- `, six under `- [ ] `. The tail is the bundled ftplugin's own
--- clause for a footnote definition, kept. Level-one long brackets, since
--- `[^\]]` would close a plain `[[`.
---@type string
local formatlistpat = [=[^\s*\%([-*+]\|\d\+[.)]\)\s\+\%(\[[ xX]\]\s\+\)\=]=]
    .. [=[\|^\[^\ze[^\]]\+\]:\&^.\{4\}]=]

--- `autoindent` is what lets `n` in 'formatoptions' indent by
--- 'formatlistpat' at all. `comments` drops the bundled ftplugin's `fb:-`,
--- `fb:*` and `fb:+`, keeping only the blockquote: as comment leaders they
--- outrank 'formatlistpat' and always hang by two columns, whatever follows
--- the bullet.
---@type { [string]: number | string | boolean }
M.local_opts = {
    shiftwidth    = 2,
    spell         = true,
    autoindent    = true,
    formatlistpat = formatlistpat,
    comments      = "n:>",
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

--- Attaches the buffer-local keymaps from `util.markdown_table` and
--- `util.markdown_list`.
---
--- `lua/filetype/init.lua` dispatches exactly one module per filetype, so
--- the compound Markdown filetypes cannot inherit this by being Markdown:
--- `filetype.nex_note` and `filetype.agentprompt` call it themselves, the same
--- way they already copy `local_opts` and `hlgroup_defs`.
---@param opts vim.api.keyset.create_autocmd.callback_args
---@return nil
M.setup = function(opts)
    require("util.markdown_table").keymap(opts.buf)
    require("util.markdown_list").keymap(opts.buf)
end

return M
