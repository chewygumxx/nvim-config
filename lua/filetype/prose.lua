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

local options = {
    spell = true,
}

---@return nil
M.setup = function()
    require("util.option").apply(options, { scope = "local" })
end

return M
