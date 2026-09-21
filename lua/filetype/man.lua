#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/man.lua
--
--

--
-- Filetype-specific configuration for manpages
--

local M = {}

local options = {
    number = true,
}

---@return nil
M.setup = function()
    require("util.option").apply(options, { scope = "local" })
end

return M
