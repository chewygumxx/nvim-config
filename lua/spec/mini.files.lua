#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/mini.files.lua
--
--

--
--  https://github.com/nvim-mini/mini.files
--

---@module "lazy"
---@module "mini.files"

---@type LazyPluginSpec
local M = {
    "nvim-mini/mini.files",
    version = false, -- 'stable' branch
    lazy    = true,

    -- Created via M.config()
    ---@type string[]
    cmd = {
        "MiniFiles",
    },
}

M.opts = {
    -- Customization of shown content
    content = {
        filter = nil, -- Predicate for which file system entries to show
        prefix = nil, -- What prefix to show to the left of file system entry
        sort = nil,   -- In which order to show file system entries
    },

    -- Module mappings created only inside explorer.
    -- Use `''` (empty string) to not create one.
    mappings = {
        close       = "q",
        go_in       = "L",
        go_in_plus  = "",
        go_out      = "H",
        go_out_plus = "",
        mark_goto   = "'",
        mark_set    = "m",
        reset       = "<BS>",
        reveal_cwd  = "@",
        show_help   = "g?",
        synchronize = "=",
        trim_left   = "<",
        trim_right  = ">",
    },

    -- General options
    options = {
        -- Whether to delete permanently or move into module-specific trash
        permanent_delete = true,
        -- Whether to use for editing directories
        use_as_default_explorer = true,
    },

    -- Customization of explorer windows
    windows = {
        width_focus   = 80, -- Width of focused window
        width_nofocus = 20, -- Width of non-focused window
        width_preview = 30, -- Width of preview window

        -- Maximum number of windows to show side by side
        max_number = math.huge,

        -- Whether to show preview of file/directory under cursor
        preview = true,
    },
}

M.config = function()
    vim.api.nvim_create_user_command(
        M.cmd[1],
        require("mini.files").open,
        { desc = "Open MiniFiles" }
    )
end

return M
