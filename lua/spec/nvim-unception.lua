#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/nvim-unception.lua
--
--

local M = {
    "samjwill/nvim-unception",
    lazy = false,
    init = function()
        vim.g.unception_block_while_host_edits = true
    end,
}

return M
