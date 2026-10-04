#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/option/general.lua
--
--

--
-- Miscellaneous option settings
--

local M = {}

local opts = {
    -- System
    clipboard = "unnamedplus",
    undofile  = true,
    mouse     = "",

    -- Tabspace
    expandtab  = true,
    shiftwidth = 4,
    tabstop    = 4,

    --textwidth = 80,
    linebreak = true, -- Break at word
    virtualedit = "block",

    -- Continue comment leader on <CR>/o/O; default is "tcqj" (missing r/o).
    -- Filetype ftplugins that set their own formatoptions still override this.
    formatoptions = "tcqjro",

    -- Search:
    -- Ignore case unless uppercase provided.
    ignorecase = true,
    smartcase  = true,

    -- Spelling: per-filetype modules toggle `spell` itself. The word list
    -- is tracked in this repository rather than left to `zg`'s default of
    -- `stdpath("data")/site/spell`, which is a cache: wiping it, or running
    -- under another NVIM_APPNAME, silently lost every added word.
    spelllang = "en",
    spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add",

    -- Per-project `.nvim.lua`, gated by `:trust` on first sight and on
    -- every change after it
    exrc = true,

    -- Consign security to oblivion
    --modelineexpr = true,
}

--- Applies this module's global option values.
---@return nil
M.setup = function()
    for opt, value in pairs(opts) do
        vim.api.nvim_set_option_value(opt, value, {})
    end
end

return M
