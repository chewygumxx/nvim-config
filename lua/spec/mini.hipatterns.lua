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

    -- The table `setup` receives, so the annotation checks what the plugin
    -- is actually given rather than a wrapper around it
    ---@type MiniHipatterns.Config
    opts = {
        highlighters = {},
    },
}

--- Adds the hex colour highlighter, which needs the plugin loaded to
--- build, then applies the options. A `config` of our own means lazy.nvim
--- no longer calls `setup(opts)`, so it is called here.
---@param _    LazyPlugin
---@param opts MiniHipatterns.Config
---@return nil
M.config = function(_, opts)
    ---@type mini.hipatterns
    local hipatterns = require("mini.hipatterns")
    local gen_hex    = hipatterns.gen_highlighter.hex_color({
        "line",                   -- <style>
        200,                      -- <priority>
        function()
            return true
        end, -- <filter>
        nil,
    })

    opts.highlighters           = opts.highlighters or {}
    opts.highlighters.hex_color = gen_hex

    hipatterns.setup(opts)
end

return M
