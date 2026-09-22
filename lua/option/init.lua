#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/option/init.lua
--
--

--
-- Setup sibling modules
--

local M = {}

--- Calls .setup() of each option module
---@return nil
M.setup = function()
    require("option.general").setup()
    require("option.fold").setup()
    require("option.view").setup()
end

return M
