#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/mini.icons.lua
--
--

---@module "lazy"
---@module "mini.icons"

---@type LazyPluginSpec
local M = {
    "nvim-mini/mini.icons",
    version = false, -- Stable branch
    lazy    = false,

    opts = {
        -- Icon style: 'glyph' or 'ascii'
        style = "glyph",

        -- Customize per category. See `:h MiniIcons.config` for details.
        default   = {},
        directory = {},
        extension = {},
        file      = {},
        filetype  = {},
        lsp       = {},
        os        = {},

        -- Control which extensions will be considered during "file" resolution
        use_file_extension = function(ext, file)
            return ext and file
        end,
    },
}

return M
