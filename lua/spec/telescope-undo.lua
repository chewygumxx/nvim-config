#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- luacheck: globals vim
-- SPDX-License-Identifier: GPL-3.0-only

-- 
-- 
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/telescope-undo.lua
-- 
-- 

local M = {
    "debugloop/telescope-undo.nvim",
    enabled = false,

    dependencies = { -- note how they're inverted to above example
        {
            "nvim-telescope/telescope.nvim",
            dependencies = { "nvim-lua/plenary.nvim" },
        },
    },
    keys = {
        { -- lazy style key map
            "<leader>u",
            "<cmd>Telescope undo<cr>",
            desc = "undo history",
        },
    },
    opts = {
        -- don't use `defaults = { }` here, do this in the main telescope spec
        extensions = {
            undo = {
                -- telescope-undo.nvim config, see below
            },
            -- no other extensions here, they can have their own spec too
        },
    },
    config = function(_, opts)
        -- Calling telescope's setup from multiple specs does not hurt, it will happily merge the
        -- configs for us. We won't use data, as everything is in it's own namespace (telescope
        -- defaults, as well as each extension).
        require("telescope").setup(opts)
        require("telescope").load_extension("undo")
    end,
}

return M
