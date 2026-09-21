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
---@module "notify"

---@type LazyPluginSpec
local M = {
    "rcarriga/nvim-notify",
    lazy = false,

    -- The README is outdated, use `:h notify.Config`
    ---@type notify.Config
    opts = {
        merge_duplicates = true,
        background_colour = "NotifyBackground",
        fps = 30,
        icons = {
            DEBUG = "",
            ERROR = "",
            INFO = "",
            TRACE = "✎",
            WARN = "",
        },
        level = 2,
        minimum_width = 50,
        render = "default",
        stages = "fade_in_slide_out",
        time_formats = {
            notification = "%T",
            notification_history = "%FT%T",
        },
        timeout = 5000,
        top_down = true,
    },
}

return M
