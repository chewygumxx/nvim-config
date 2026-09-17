#!/bin/false
-- vim:set foldlevel=1 foldmethod=expr filetype=lua:
-- luacheck: globals vim
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/home/dot_config/nvim/lua/plugin_manager.lua
--

--
-- https://lazy.folke.io/configuration
--

local M = {}

local data     = vim.fn.stdpath("data") .. "/lazy"
local state    = vim.fn.stdpath("state") .. "/lazy"
local lazypath = data .. "/lazy.nvim"

local cgxx_mod = _G.require_guard("cgxx") or {}
local cgxx     = cgxx_mod.lazy or {}

---@type LazyConfig
local opts = {
    root     = data, -- Plugin Installation Directory
    lockfile = state .. "/lock.json", -- Post-Update Lockfile
    state    = state .. "/state.json", -- State Infomation file

    -- Plugin Specs
    ---@type LazySpec
    spec = {
        { import = "spec" },
    },

    -- Plugin Spec Defaults
    ---@type LazySpec
    defaults = cgxx.default_spec
        or {
            lazy = false,
        },

    -- Locally Available Plugins
    dev = {
        path     = cgxx.devpath or vim.fn.expand("~") .. "/dev",
        patterns = { "chewygumxx" },
        fallback = true, -- Use git if not found
    },

    -- TODO(@chewygum): [LOW] Investigate
    pkg = {
        enabled  = true,
        cache    = state .. "/pkg_cache.lua",
        versions = true, -- Honour versions in pkg sources
        sources  = {
            "lazy",
            "rockspec",
            "packspec",
        },
    },

    -- TODO(@chewygum): [LOW] Investigate
    rocks = {
        enabled   = true,
        root      = data .. "/rocks",
        server    = "https://lumen-oss.github.io/rocks-binaries/",
        hererocks = nil,
    },

    install = {
        -- Install missing plugins on startup
        missing = true,

        -- Prioritised colorscheme list to attempt to load during installation
        -- Handled by (with remarkable brilliance):
        -- - LazyCoreLoader.install_missing()
        -- - LazyCoreLoader.colorscheme(color)
        ---@type string[]
        colorscheme = cgxx_mod.colorscheme or { "middlenight_blue" },
    },

    diff = { cmd = "git" },

    -- Auto-Update Check
    -- This may be why I occasionally experience lag in Herdr panes
    -- TODO(@chewygumxx): Investigate
    checker = {
        enabled      = cgxx.checker == true,
        concurrency  = nil, -- Concurrent/Parallel Check Limit
        notify       = false,
        frequency    = 3600, -- Check Frequency (seconds)
        check_pinned = false, -- Check Version Pinned Packages (requires manual plugin spec edit)
    },

    performance = {
        cache          = { enabled = true },
        reset_packpath = true, -- reset the package path to improve startup time
        rtp            = {
            reset            = true, -- reset the runtime path to $VIMRUNTIME and your config ctory
            paths            = {}, -- Custom runtime paths
            disabled_plugins = {},
        },
    },

    -- Generate `:help` documentation from README
    readme = {
        enabled            = cgxx.readme ~= false,
        root               = data .. "/readme",
        files              = { "README.md", "lua/**/README.md" },
        skip_if_doc_exists = true,
    },

    -- Additional stats provided on 'Debug' tab
    profiling = {
        loader  = cgxx.profile == true, -- Assess all package.loaders
        require = cgxx.profile == true, -- Track each new require
    },
}

-- Watch configuration file and reload UI on change
opts.change_detection = {
    enabled = cgxx.watch_config == true,
    notify  = true,
}

opts.ui = {
    size        = { width = 0.8, height = 0.8 },
    wrap        = true, -- Line Wrapping
    pills       = true, -- Header Icons
    backdrop    = 40, -- Backdrop opacity
    border      = "none", -- `nvim_open_win()` config.border
    title       = nil,
    title_pos   = "center",
    browser     = vim.env.BROWSER,
    throttle    = 20, -- Redraw frequency
    icons       = {
        cmd        = " ",
        config     = "",
        event      = " ",
        favorite   = " ",
        ft         = " ",
        init       = " ",
        import     = " ",
        keys       = " ",
        lazy       = "󰒲 ",
        loaded     = "●",
        not_loaded = "○",
        plugin     = " ",
        runtime    = " ",
        require    = "󰢱 ",
        source     = " ",
        start      = " ",
        task       = "✔ ",
        list       = { "●", "➜", "★", "‒" },
    },
    custom_keys = { -- - Shown in :Lazy help
        ["<localleader>l"] = {
            function(plugin)
                require("lazy.util").float_term({ "lazygit", "log" }, {
                    cwd = plugin.dir,
                })
            end,
            desc = "Open lazygit log",
        },
        ["<localleader>t"] = {
            function(plugin)
                require("lazy.util").float_term(nil, {
                    cwd = plugin.dir,
                })
            end,
            desc = "Open terminal in plugin.dir",
        },
    },
}

local git_clone = {
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
}

local install_legacy = function()
    local out = vim.fn.system(git_clone)
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end

local install = function()
    local syscall = vim.system(git_clone, { text = true }):wait()
    if syscall.code ~= 0 then
        vim.notify(
            table.concat({
                "Failed to clone lazy.nvim",
                "Exited with code: " .. tostring(syscall.code),
                syscall.stderr,
                "Press any key to exit",
            }, "\n"),
            vim.log.levels.ERROR
        )
        vim.fn.getchar()
        os.exit(1)
    end
end

M.setup = function()
    if not (vim.uv or vim.loop).fs_stat(lazypath) then
        vim.notify("Installing lazy.nvim package manager", vim.log.levels.INFO)
        if vim.version.ge(vim.version(), { 0, 10, 0 }) then
            install()
        else
            install_legacy()
        end
    end

    vim.opt.rtp:append(lazypath)
    require("lazy").setup(opts)
end

return M
