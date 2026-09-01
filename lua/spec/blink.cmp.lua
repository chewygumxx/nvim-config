#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

-- 
-- 
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/blink.cmp.lua
-- 
-- 

-- 
-- 
-- 

local M = {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts_extend = { "sources.default" },
}

M.opts = {
    appearance = {
        nerd_font_variant = "normal"
    },
    
    completion = {
        documentation = { auto_show = false },
        list = {
            selection = { preselect = false }, -- For <CR> (Enter) keymap
        }
    },
    
    sources = {
        default = { "lsp", "path", "snippets", "buffer", "lazydev" },
        providers = {
            lazydev = {
                name = "LazyDev",
                module = "lazydev.integrations.blink",
                -- make lazydev completions top priority (see `:h blink.cmp`)
                score_offset = 100,
            },
        },
    },

    fuzzy = {
        implementation = "prefer_rust_with_warning"
    },
}

-- See :h blink-cmp-config-keymap for defining your own keymap
-- https://cmp.saghen.dev/configuration/keymap.html
M.opts.keymap = {
    preset = "none",
    
    ["<C-e>"]   = { "cancel", "fallback" },
    ["<C-Esc>"] = { "cancel", "fallback" },
    ["<CR>"]    = { "accept", "fallback" },

    ["<Down>"]  = { "select_next", "fallback" },
    ["<C-j>"]   = { "select_next", "fallback" },
    ["<Up>"]    = { "select_prev", "fallback" },
    ["<C-k>"]   = { "select_prev", "fallback" },
    
    ["<Tab>"]   = { "snippet_forward",  "select_next", "fallback" },
    ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },

    ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
    ["<C-p>"]   = { "scroll_documentation_up",   "fallback" },
    ["<C-n>"]   = { "scroll_documentation_down", "fallback" },
}



return M
