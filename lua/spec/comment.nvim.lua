#!/bin/false
-- vim: expandtab:shiftwidth=4:ft=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/comment.nvim.lua
--
--

--
-- Cross-filetype commenting utility sourcing Neovim-native treesitter and
-- commentstring to provide uniform comment operation via keymap
--


---@module "lazy"
---@type LazySpec
local M = {
    url     = "https://github.com/numToStr/Comment.nvim",
    enabled = true,
    lazy    = true, -- See M.keys
}

M.opts = {
    padding   = false,  -- Add a space between comment and content
    sticky    = true,   -- Whether the cursor should remain at its position
    ignore    = nil,    -- Lines ignored
    pre_hook  = nil,    -- Function called before
    post_hook = nil,    -- Function called after 
    
    mappings = {        -- Enable keybindings
        basic = true,   -- Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
        extra = true,   -- Extra mapping; `gco`, `gcO`, `gcA`
    },                     

    -- Toggle mappings in NORMAL
    toggler = {
        line  = 'gcc',
        block = 'gbc',
    },                     

    -- Operator-pending mappings in NORMAL and VISUAL
    opleader = {
        line  = 'gc',
        block = 'gb',
    },                     
                           
    extra = {           
        above = 'gcO',  -- Add comment on the line above
        below = 'gco',  -- Add comment on the line below
        eol   = 'gcA',  -- Append comment to end of line
    },
}

M.keys = {
    { M.opts.toggler.line,                        desc = "Comment: Toggle line"        },
    { M.opts.toggler.block,                       desc = "Comment: Toggle block"       },
    { M.opts.opleader.line,  mode = { "n", "v" }, desc = "Comment: line operator"      },
    { M.opts.opleader.block, mode = { "n", "v" }, desc = "Comment: block operator"     },
    { M.opts.extra.above,                         desc = "Comment: Add above"          },
    { M.opts.extra.below,                         desc = "Comment: Add below"          },
    { M.opts.extra.eol,                           desc = "Comment: Append to line end" },
}

return M
