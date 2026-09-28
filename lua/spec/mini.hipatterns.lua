#!/bin/false
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
    -- Named fields: `hex_color` merges a table of options over its own
    -- defaults, so the positional `{ "line", 200, filter }` this once
    -- passed was ignored whole and the style fell back to "full". 200 and
    -- an always-true filter are the defaults, so only the style is stated.
    local gen_hex = hipatterns.gen_highlighter.hex_color({
        style = "line",
    })

    opts.highlighters           = opts.highlighters or {}
    opts.highlighters.hex_color = gen_hex

    hipatterns.setup(opts)
end

return M
