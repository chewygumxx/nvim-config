#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/dosini.lua
--
--

--
-- dosini filetype settings
--

local M = {}

local options = {
    commentstring = "# %s",
}

---@return nil
M.setup = function()
    _G.require_guard("util.option").apply(options, { scope = "local" })
end

return M
