#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/snacks.nvim.lua
--
--

--
-- https://github.com/folke/snacks.nvim
-- `:h snacks-<module>`
--

---@module "lazy"
---@module "snacks"

---@type LazyPluginSpec
local M = {
    "folke/snacks.nvim",
    enabled = false,
    lazy = false,
    priority = 1000, -- Referenced by other plugins and specs
}

---@type snacks.Config
M.opts = {
    animate      = {
        duration = 20, -- ms per step
        easing = "inOutExpo",
        fps = 120,
    },
    indent       = { enabled = false },
    input        = { enabled = false },
    picker       = { enabled = false },
    notifier     = { enabled = false },
    quickfile    = { enabled = false },
    scope        = { enabled = false },
    scroll       = { enabled = false },
    statuscolumn = { enabled = false },
    words        = { enabled = false },
}

M.opts.bigfile   = {
    notify      = true,
    size        = 1024 * 1024, -- 1MB
    line_length = 1000, -- average line length (minified files)

    -- Enable or disable features when big file detected
    ---@param ctx {buf: number, ft:string}
    setup = function(ctx)
        if vim.fn.exists(":NoMatchParen") ~= 0 then
            vim.cmd([[NoMatchParen]])
        end

        require("snacks").util.wo(0, {
            foldmethod = "manual",
            statuscolumn = "",
            conceallevel = 0,
        })

        vim.b.treesitter             = false
        vim.b.completion             = false
        vim.b.minianimate_disable    = true
        vim.b.minihipatterns_disable = true

        vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ctx.buf) then
                vim.bo[ctx.buf].syntax = ctx.ft
            end
        end)
    end,
}
M.opts.dashboard = {
    -- Dashboard Position, nil for center
    row = nil,
    col = nil,

    width    = 60,
    pane_gap = 4, -- empty columns between vertical panes

    autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",

    sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
    },

    -- These settings are used by some built-in sections
    preset = {
        -- Defaults to a picker that supports `fzf-lua`, `telescope.nvim` and `mini.pick`
        ---@type fun(cmd:string, opts:table)|nil
        pick = nil,

        -- Used by the `header` section
        header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],

        -- Used by the `keys` section to show keymaps.
        -- Set your custom keymaps here.
        -- When using a function, the `items` argument are the default keymaps.
        ---@type snacks.dashboard.Item[]
        keys = {
            {
                icon   = " ",
                key    = "f",
                desc   = "Find File",
                action = ":lua Snacks.dashboard.pick('files')",
            },
            {
                icon   = " ",
                key    = "n",
                desc   = "New File",
                action = ":ene | startinsert",
            },
            {
                icon   = " ",
                key    = "g",
                desc   = "Find Text",
                action = ":lua Snacks.dashboard.pick('live_grep')",
            },
            {
                icon   = " ",
                key    = "r",
                desc   = "Recent Files",
                action = ":lua Snacks.dashboard.pick('oldfiles')",
            },
            {
                icon   = " ",
                key    = "c",
                desc   = "Config",
                action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
            },
            {
                icon    = " ",
                key     = "s",
                desc    = "Restore Session",
                section = "session",
            },
            {
                icon    = "󰒲 ",
                key     = "L",
                desc    = "Lazy",
                action  = ":Lazy",
                enabled = package.loaded.lazy ~= nil,
            },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
    },

    -- item field formatters
    formats = {
        icon = function(item)
            if item.file and item.icon == "file" or item.icon == "directory" then
                return require("snacks")
                    .dashboard
                    .icon(item.file, item.icon)
            end
            return { item.icon, width = 2, hl = "icon" }
        end,
        footer = { "%s", align = "center" },
        header = { "%s", align = "center" },
        file = function(item, ctx)
            local fname = vim.fn.fnamemodify(item.file, ":~")
            fname       = ctx.width and #fname > ctx.width
                and vim.fn.pathshorten(fname) or fname
            if #fname > ctx.width then
                local dir  = vim.fn.fnamemodify(fname, ":h")
                local file = vim.fn.fnamemodify(fname, ":t")
                if dir and file then
                    file  = file:sub(-(ctx.width - #dir - 2))
                    fname = dir .. "/…" .. file
                end
            end
            local dir, file = fname:match("^(.*)/(.+)$")
            return dir and { { dir .. "/", hl = "dir" }, { file, hl = "file" } }
                or {
                    {
                        fname,
                        hl = "file",
                    },
                }
        end,
    },
}
M.opts.explorer  = {
    tree  = true,
    watch = true, -- File changes

    git_status      = true,
    git_untracked   = true,
    git_status_open = true, -- Recursive for open directories

    diagnostics      = true,
    diagnostics_open = false, -- Recursive for open directories

    -- Glob patterns
    exclude = {},
    include = {},             -- Precedence over `exclude`, `ignored` and `hidden`

    finder        = "explorer",
    sort          = { fields = { "sort" } },
    supports_live = true,
    follow_file   = true,
    focus         = "list",
    auto_close    = false,
    jump          = { close = false },

    -- to show the explorer to the right, add the below to
    -- your config under `opts.picker.sources.explorer`
    -- layout = { layout = { position = "right" } },
    layout = { preset = "sidebar", preview = false },

    formatters = {
        file = { filename_only = true },
        severity = { pos = "right" },
    },

    matcher = { sort_empty = false, fuzzy = false },
    config = function(opts)
        return require("snacks.picker.source.explorer").setup(opts)
    end,

    win = {
        list = {
            keys = {
                ["<BS>"]      = "explorer_up",
                ["l"]         = "confirm",
                ["h"]         = "explorer_close", -- close directory
                ["a"]         = "explorer_add",
                ["d"]         = "explorer_del",
                ["r"]         = "explorer_rename",
                ["c"]         = "explorer_copy",
                ["m"]         = "explorer_move",
                ["o"]         = "explorer_open", -- open with system application
                ["P"]         = "toggle_preview",
                ["y"]         = { "explorer_yank", mode = { "n", "x" } },
                ["p"]         = "explorer_paste",
                ["u"]         = "explorer_update",
                ["<c-c>"]     = "tcd",
                ["<leader>/"] = "picker_grep",
                ["<c-t>"]     = "terminal",
                ["."]         = "explorer_focus",
                ["I"]         = "toggle_ignored",
                ["H"]         = "toggle_hidden",
                ["Z"]         = "explorer_close_all",
                ["]g"]        = "explorer_git_next",
                ["[g"]        = "explorer_git_prev",
                ["]d"]        = "explorer_diagnostic_next",
                ["[d"]        = "explorer_diagnostic_prev",
                ["]w"]        = "explorer_warn_next",
                ["[w"]        = "explorer_warn_prev",
                ["]e"]        = "explorer_error_next",
                ["[e"]        = "explorer_error_prev",
            },
        },
    },
}

return M
