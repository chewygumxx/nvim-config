#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/man.lua
--
--

--
-- Filetype-specific configuration for Manpages
--

local M = {}

---@type { [string]: number | string | boolean }
M.local_opts = {
    number         = true,
    relativenumber = false,
}

return M
