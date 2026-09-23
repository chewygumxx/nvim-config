#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/mini.hipatterns.lua
--
--

---@module "lazy"

---@type LazyPluginSpec
local M = {
    "nvim-mini/mini.hipatterns",
    lazy = false,

    ---@type MiniHipatterns.Config
    opts = {
        hipatterns = {
            highlighters = {},
        },
    },
}

M.config = function()
    local gen_hex                            = require("mini.hipatterns")
        .gen_highlighter
        .hex_color({
            "line",                   -- <style>
            200,                      -- <priority>
            function()
                return true
            end, -- <filter>
            nil,
        })
    M.opts.hipatterns.highlighters.hex_color = gen_hex

    require("mini.hipatterns").setup(M.opts.hipatterns)
end

return M
