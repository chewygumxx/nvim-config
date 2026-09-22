#!/bin/false
-- vim:set expandtab shiftwidth=4 foldlevel=1 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/lazy.lua
--
--

--
-- lazy.nvim
-- The quinessential lazy-loading plugin manager for Neovim
-- https://lazy.folke.io/configuration
--

local M = {}

local joinpath  = vim.fs.joinpath
local data_dir  = vim.fn.stdpath("data")
local state_dir = vim.fn.stdpath("state")

---@class LazyConfig
M.defaults = {
    --- Repository URL or GitHub slug
    "chewygumxx/lazy.nvim" or nil,

    -- Resolved URL
    url = "https://github.com/chewygumxx/lazy.nvim" or nil,

    -- Repository branch
    branch = "chewygumxx" or nil,

    -- Name of lazy.nvim, sets directory names
    name = "lazy" or nil,

    ---@type LazySpec
    spec = "spec" or nil,

    -- Plugin installation directory
    root = joinpath(data_dir, "lazy") or nil,

    -- lazy.nvim installation directory
    path = joinpath(data_dir, "lazy", "lazy.nvim") or nil,

    -- State information file
    state = joinpath(state_dir, "lazy", "state.json") or nil,

    -- Post-update lockfile
    lockfile = joinpath(state_dir, "lazy", "lock.json") or nil,

    -- Load project-local `.lazy.lua` LazySpec[] file`
    local_spec = true or nil,

    -- Concurrent task limit
    concurrency = jit.os:find("Windows")
        and (vim.uv.available_parallelism() * 2)
        or nil,

    diff = {
        cmd = "git",
    },

    git = {
        log = { "-3" }, -- Default `:Lazy log` arguments
        timeout = 120,  -- Process time to live

        -- Can also be git@github.com:%s.git
        url_format = "https://github.com/%s.git",

        -- Set to false for `git` versions < v2.19.0
        filter = true,

        -- Rate limiting of `git` network operation
        throttle = {
            enabled = false,

            -- Maximum: 2 operations every 5 seconds
            rate = 2,
            duration = 5 * 1000, -- in ms
        },

        -- Time in seconds to wait before running fetch again for a plugin.
        cooldown = 0,
    },

    -- Plugin spec defaults
    defaults = {
        --- Lazy load by default, lazy-load averse plugins may break
        lazy = false,

        version = nil,

        -- Utilised for programmatically deactivating plugins
        ---@type nil | boolean | fun(self:LazyPlugin):boolean | nil
        cond = nil,
    },

    -- Locally available plugins
    dev = {
        -- (Returns) Local plugin parent directory
        ---@type string | fun(plugin: LazyPlugin): string
        path = vim.fs.normalize("~/dev"),

        -- Match patterns for resolving whether to source locally
        patterns = { "chewygumxx" },

        -- Use git if not found
        fallback = true,
    },

    install = {
        -- Install missing plugins on startup
        missing = true,

        -- Prioritised colorscheme list to attempt to load during installation
        colorscheme = { "middlenight_blue" },
    },

    performance = {
        cache          = { enabled = true },
        reset_packpath = true, -- Reset the package path to improve startup time
        rtp            = {
            -- Reset the runtime path to $VIMRUNTIME and your config directory
            reset            = true,
            paths            = {}, -- Custom runtime paths
            disabled_plugins = {},
        },
    },

    -- Generate `:help` documentation from README
    readme = {
        enabled            = true,
        root               = joinpath(data_dir, "readme"),
        files              = { "README.md", "lua/**/README.md" },
        skip_if_doc_exists = true,
    },

    -- Additional stats provided on the "Debug" tab
    profiling = {
        loader  = false, -- Assess all package.loaders
        require = false, -- Track each new require
    },

    -- Watch configuration files and reload the UI on change
    change_detection = {
        enabled = false,
        notify  = true,
    },

    -- Automatic update checks
    checker = {
        enabled     = vim.env.HERDR_ENV == nil and vim.env.TERMUX_VERSION == nil,
        concurrency = nil, -- Concurrent check limit
        notify      = false,
        frequency   = 3600, -- Check frequency (seconds)
        -- Check version-pinned packages (requires manual plugin spec edit)
        check_pinned = false,
    },

    pkg = {
        enabled  = true,
        cache    = joinpath(state_dir, "pkg_cache.lua"),
        versions = true, -- Honour versions in pkg sources
        sources  = { "lazy", "rockspec", "packspec" },
    },

    rocks = {
        enabled   = true,
        root      = joinpath(data_dir, "rocks"),
        server    = "https://lumen-oss.github.io/rocks-binaries/",
        hererocks = nil,
    },

    ui = {
        size      = { width = 0.8, height = 0.8 },
        wrap      = true, -- Line wrapping
        pills     = true, -- Header icons
        backdrop  = 40, -- Backdrop blend (0 opaque, 100 transparent)
        border    = "none", -- `nvim_open_win()` config.border
        title     = nil,
        title_pos = "center",
        browser   = vim.env.BROWSER,
        throttle  = 20, -- Redraw throttle (ms)

        -- Shown in `:Lazy` help
        custom_keys = {
            ["<localleader>t"] = {
                function(plugin)
                    require("lazy.util").float_term(nil, { cwd = plugin.dir })
                end,
                desc = "Open terminal in plugin.dir",
            },
        },

        icons = {
            cmd        = " ",
            config     = "",
            debug      = "● ",
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
    },
    debug = false,
}

--- Clones remote repository of lazy.nvim
---@param url    string Repository URL
---@param path   string Clone destination
---@param branch string Repository branch
---@return number syscall_code Exit code of git clone
function M.install(url, path, branch)
    vim.notify("Installing lazy.nvim package manager", vim.log.levels.INFO)
    local syscall = vim.system({
        "git",
        "clone",
        "--filter=blob:none",
        type(branch) == "string" and "--branch=" .. branch or nil,
        url,
        path,
    }, { text = true }):wait()
    if syscall.code ~= 0 then
        vim.notify("Failed to clone lazy.nvim", vim.log.levels.ERROR)
        vim.notify(
            table.concat({
                "Exited with code: " .. tostring(syscall.code),
                syscall.stderr,
            }, "\n"),
            vim.log.levels.WARN
        )
    end
    return syscall.code
end

--- Installs lazy.nvim if not found, merges opts with defaults and calls
--- require("lazy").setup(opts)
---@param opts? LazyConfig
---@return nil
M.setup = function(opts)
    opts     = vim.tbl_deep_extend("force", M.defaults, opts or {})
    opts.url = opts.url or opts.git.url_format:format(opts[1])

    if not (vim.uv or vim.loop).fs_stat(opts.path) then
        local code = M.install(opts.url, opts.path, opts.branch)
        if code ~= 0 then
            return
        end
    end
    vim.opt.rtp:append(opts.path)
    require("lazy").setup(opts)
end

return M
