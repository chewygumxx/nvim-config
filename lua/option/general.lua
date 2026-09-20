#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

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

    -- Spelling: language only, per-filetype modules toggle `spell` itself
    spelllang = "en",

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
