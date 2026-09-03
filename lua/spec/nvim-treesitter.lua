#!/bin/false
-- vim: expandtab:shiftwidth=4
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/nvim-treesitter.lua
--
--

-- 
-- Neovim treesitter parser manager and query collection. Also includes
-- staged features for potential future Neovim-native implementation.
--

---@module "lazy"
---@type LazySpec
local M = {
    url     = "https://github.com/nvim-treesitter/nvim-treesitter.git",
    enabled = true,
    branch  = 'main',
    build   = ':TSUpdate',
    lazy    = false,
}

local ensure_installed = {
    -- https://github.com/nvim-treesitter/nvim-treesitter/blob/main/SUPPORTED_LANGUAGES.md
    "awk",
    -- https://github.com/Beaglefoot/tree-sitter-awk

    "bash",
    -- https://github.com/tree-sitter/tree-sitter-bash

    "comment",
    -- https://github.com/stsewd/tree-sitter-comment

    "css",
    -- https://github.com/tree-sitter/tree-sitter-css

    "csv", "psv", "tsv",
    -- https://github.com/tree-sitter-grammars/tree-sitter-csv

    "desktop",
    -- https://github.com/ValdezFOmar/tree-sitter-desktop
    -- For both .desktop and .directory files
    
    "diff",
    -- https://github.com/tree-sitter-grammars/tree-sitter-diff
    -- Required by: gitcommit

    --"editorconfig",
    -- https://github.com/ValdezFOmar/tree-sitter-editorconfig

    --"fish",
    -- https://github.com/ram02z/tree-sitter-fish

    --"git_config",
    -- https://github.com/the-mikedavis/tree-sitter-git-config

    "git_rebase",
    -- https://github.com/the-mikedavis/tree-sitter-git-rebase
    -- Required by: gitcommit

    --"gitattributes",
    -- https://github.com/tree-sitter-grammars/tree-sitter-gitattributes

    "gitcommit",
    -- https://github.com/gbprod/tree-sitter-gitcommit
    -- Depends on: diff, git_rebase

    "gitignore",
    -- https://github.com/shunsambongi/tree-sitter-gitignore

    --"gnuplot",
    -- https://github.com/dpezto/tree-sitter-gnuplot

    --"go",
    -- https://github.com/tree-sitter/tree-sitter-go

    "gotmpl",
    -- https://github.com/ngalaiko/tree-sitter-go-template
    -- Golang text/template
  
    --"gpg",
    -- https://github.com/tree-sitter-grammars/tree-sitter-gpg-config
    -- gpg config files

    --"graphql",
    -- https://github.com/bkegley/tree-sitter-graphql

    --"haskell",
    -- https://github.com/tree-sitter-grammars/tree-sitter-haskell

    --"hcl",
    -- https://github.com/tree-sitter-grammars/tree-sitter-hcl

    --"helm",
    -- https://github.com/ngalaiko/tree-sitter-go-template

    --"hjson",
    -- https://github.com/winston0410/tree-sitter-hjson

    "html",
    -- https://github.com/tree-sitter/tree-sitter-html

    "html_tags",
    -- Queries only

    --"htmldjango",
    -- https://github.com/interdependence/tree-sitter-htmldjango

    --"http",
    -- https://github.com/rest-nvim/tree-sitter-http

    --"hurl",
    -- https://github.com/pfeiferj/tree-sitter-hurl

    --"hyprlang",
    -- https://github.com/tree-sitter-grammars/tree-sitter-hyprlang

    "ini",
    -- https://github.com/justinmk/tree-sitter-ini

    "javascript",
    -- https://github.com/tree-sitter/tree-sitter-javascript

    --"jq",
    -- https://github.com/flurie/tree-sitter-jq

    --"jsdoc",           
    -- https://github.com/tree-sitter/tree-sitter-jsdoc

    "json",
    -- https://github.com/tree-sitter/tree-sitter-json

    --"json5",
    -- https://github.com/Joakker/tree-sitter-json5

    --"jsonnet",
    -- https://github.com/sourcegraph/tree-sitter-jsonnet

    --"kdl",
    -- https://github.com/tree-sitter-grammars/tree-sitter-kdl

    --"latex",
    -- https://github.com/latex-lsp/tree-sitter-latex

    "lua",
    -- https://github.com/tree-sitter-grammars/tree-sitter-lua

    "luadoc",
    -- https://github.com/tree-sitter-grammars/tree-sitter-luadoc

    "luap",
    -- https://github.com/tree-sitter-grammars/tree-sitter-luap
    -- Lua Patterns

    "markdown",
    "markdown_inline",
    -- https://github.com/tree-sitter-grammars/tree-sitter-markdown

    --"mermaid",
    -- https://github.com/monaqa/tree-sitter-mermaid

    --"nginx",
    -- https://github.com/opa-oz/tree-sitter-nginx

    --"nim",
    -- https://github.com/alaviss/tree-sitter-nim

    --"nim_format_string",
    -- https://github.com/aMOPel/tree-sitter-nim-format-string

    --"nix",
    -- https://github.com/nix-community/tree-sitter-nix

    --"nu",
    -- https://github.com/nushell/tree-sitter-nu

    --"passwd",
    -- https://github.com/ath3/tree-sitter-passwd
  
    --"pem",
    -- https://github.com/tree-sitter-grammars/tree-sitter-pem

    --"perl",
    -- https://github.com/tree-sitter-perl/tree-sitter-perl

    "printf",
    -- https://github.com/tree-sitter-grammars/tree-sitter-printf

    --"pymanifest",
    -- https://github.com/tree-sitter-grammars/tree-sitter-pymanifest

    "python",
    -- https://github.com/tree-sitter/tree-sitter-python

    --"query",
    -- https://github.com/tree-sitter-grammars/tree-sitter-query
    -- Treesitter query language

    "regex",
    -- https://github.com/tree-sitter/tree-sitter-regex

    --"requirements",
    -- https://github.com/tree-sitter-grammars/tree-sitter-requirements
    -- pip requirements file

    --"rst",
    -- https://github.com/stsewd/tree-sitter-rst

    --"ruby",
    -- https://github.com/tree-sitter/tree-sitter-ruby

    "rust",
    -- https://github.com/tree-sitter/tree-sitter-rust

    --"scss",
    -- https://github.com/serenadeai/tree-sitter-scss

    "sql",
    -- https://github.com/derekstride/tree-sitter-sql

    --"ssh_config",
    -- https://github.com/tree-sitter-grammars/tree-sitter-ssh-config

    --"superhtml"
    -- https://github.com/kristoff-it/superhtml

    "toml",
    -- https://github.com/tree-sitter-grammars/tree-sitter-toml

    --"tsx",
    -- https://github.com/tree-sitter/tree-sitter-typescript

    "typescript",
    -- https://github.com/tree-sitter/tree-sitter-typescript

    --"vim",
    -- https://github.com/tree-sitter-grammars/tree-sitter-vim

    --"vimdoc",
    -- https://github.com/neovim/tree-sitter-vimdoc

    "xml",
    -- https://github.com/tree-sitter-grammars/tree-sitter-xml

    "yaml",
    -- https://github.com/tree-sitter-grammars/tree-sitter-yaml

    --"zig",
    -- https://github.com/tree-sitter-grammars/tree-sitter-zig

    "zsh",
    -- https://github.com/georgeharker/tree-sitter-zsh
}

local ignore_filetypes = {
    'checkhealth',
    'lazy',
    'qf',   -- QuickFix
    'mason',
    'snacks_dashboard',
    'snacks_notif',
    'snacks_win',
    'text',
    'man',
}

-- Ripped from:
-- https://www.reddit.com/r/neovim/comments/1pndf9e/my_new_nvimtreesitter_configuration_for_the_main/
M.config = function()
    local custom_predicates = _G.require_guard("util.treesitter")
    if custom_predicates then
        custom_predicates.setup()
    end

    vim.treesitter.language.register('ini',    'systemd' )
    vim.treesitter.language.register('gotmpl', 'template')

    local ts = require('nvim-treesitter')
    -- Install core parsers after lazy.nvim finishes loading all plugins
    vim.api.nvim_create_autocmd('User', {
        pattern  = 'LazyDone',
        callback = function() ts.install(ensure_installed, { max_jobs = 8,})  end,
        once     = true,
    })

    -- State tracking for async parser loading
    local parsers_loaded  = {}
    local parsers_pending = {}
    local parsers_failed  = {}

    -- Helper to start highlighting and indentation
    local start = function(buf, lang)
        local ok = pcall(vim.treesitter.start, buf, lang)
        if ok then
            if vim.treesitter.query.get(lang, "indents") then
                vim.bo.indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"
            end
            if vim.treesitter.query.get(lang, "folds") then
                vim.wo.foldexpr   = "v:lua.vim.treesitter.foldexpr()"
              --vim.wo.foldmethod = "expr"
            end
        end
        return ok
    end

    -- Decoration provider for async parser loading
    vim.api.nvim_set_decoration_provider(vim.api.nvim_create_namespace('treesitter.async'), {
        on_start = vim.schedule_wrap(function()
            if #parsers_pending == 0 then
                return false
            end

            for _, data in ipairs(parsers_pending) do
                if vim.api.nvim_buf_is_valid(data.buf) then
                    if start(data.buf, data.lang) then
                        parsers_loaded[data.lang] = true
                    else
                        parsers_failed[data.lang] = true
                    end
                end
            end
            parsers_pending = {}
        end),
    })

    -- Auto-install parsers and enable highlighting on FileType
    vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('TreesitterSetup', { clear = true }),
        desc  = 'Enable treesitter functionality',
        callback = function(event)
          --vim.notify(require('inspect')(event), vim.log.levels.INFO)

            -- Filesize Limit
            local megabyte = 1024 * 1024
            if vim.fn.getfsize(event.file) > (vim.g.large_filesize or megabyte) then
                vim.notify("Filesize exceeded treesitter limit: (see \"Filesize Limit\" of spec/nvim-treesitter.lua)", 
                    vim.log.levels.INFO)
                return
            end

            -- Filetype Ignore
            if vim.tbl_contains(ignore_filetypes, event.match) then
                return
            end

            local lang = vim.treesitter.language.get_lang(event.match) or event.match
            local buf  = event.buf

            if parsers_failed[lang] then
                vim.notify("Treesitter parser failed for lang: " .. lang, vim.log.levels.WARN)
                return
            end

            if parsers_loaded[lang] then
                -- Parser already loaded, start immediately (fast path)
                start(buf, lang)
            else
                -- Queue for async loading
                table.insert(parsers_pending, { buf = buf, lang = lang })
            end

            -- Auto-install missing parsers (async, no-op if already installed)
            ts.install({ lang })
        end,
    })
end

return M
