#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/spec.lua
--
--

---@module "lazy"

---@type LazySpec
local M = {
    { import = "spec" },
    {
        name = "overrides",
        import = function()
            local elide = {
                "folke/noice.nvim",
                "folke/snacks.nvim",
                "L3M0NAD3/LuaSnip",
                "mikavilpas/yazi.nvim",
                "stevearc/oil.nvim",
                "kndndrj/nvim-dbee",
                "MunifTanjim/nvim-nio",
                "OXY2DEV/markview.nvim",
                "folke/which-key.nvim",
                "nvim-neorg/neorg",
                "rcarriga/nvim-notify",
                "nvim-telescope/telescope.nvim",
            }
            local ret   = {}
            for _, plugin in ipairs(elide) do
                table.insert(ret, { cond = false, plugin })
            end
            return ret
        end,
    },
}

return M
