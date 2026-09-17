#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/nvim-jqx.lua
--
--

---@module "lazy"
---@type LazySpec
local M = {
    "gennaro-tedesco/nvim-jqx",

    ft = { "json", "yaml" },
    --event = { "BufReadPost" },
}

return M
