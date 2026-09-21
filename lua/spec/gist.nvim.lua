#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/gist.nvim.lua
--
--

local M = {
    "Rawnly/gist.nvim",
    lazy = true,

    opts = {},

    cmd = { "GistCreate", "GistCreateFromFile", "GistsList" },
}

return M
