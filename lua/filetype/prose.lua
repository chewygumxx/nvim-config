#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/prose.lua
--
--

--
-- Shared settings for prose filetypes with no other overrides
--

local M = {}

---@type { [string]: number | string | boolean }
M.local_opts = {
    spell = true,
}

return M
