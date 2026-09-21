#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/nvim-notify.lua
--
--

---@module "lazy"

---@type LazyPluginSpec
local M = {
    "rcarriga/nvim-notify",
    lazy = false,

    opts = {},
}

return M
