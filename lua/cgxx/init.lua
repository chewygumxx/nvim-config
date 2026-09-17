#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/cgxx/init.lua
--
--

---@class cgxx: cgxx.config
local M = {}

---@param opts cgxx.config
---@return cgxx.config
M.setup = function(opts)
    local config = require("cgxx.config").setup(opts or {})
    for key, value in pairs(config) do
        M[key] = value
    end
    return config
end

return M
