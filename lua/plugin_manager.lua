-- vim: foldlevel=1:foldmethod=expr

--
--
-- ~/.config/nvim/lua/plugin_manager/init.lua
--
--

--
-- https://github.com/folke/lazy.nvim
--

local lazy = {}

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local spec  = {{ import = "spec" }}

local opts = {
    -- Plugin Installation Directory
    root     = vim.fn.stdpath("data") .. "/lazy",
    -- Post-Update Lockfile
    lockfile = vim.fn.stdpath("state") .. "/lazy/lock.json", 
    -- State Infomation file
    state    = vim.fn.stdpath("state") .. "/lazy/state.json",
    
    -- Default Plugin Spec
    defaults = {
        lazy    = false, -- should plugins be lazy-loaded?
        version = "*",   -- Always use the latest version lmao
        cond    = nil,   ---@type boolean|fun(self:LazyPlugin):boolean|nil
    },
    dev = { path = vim.fn.expand('~') .. "/dev", },
    pkg = {
        enabled  = true,
        cache    = vim.fn.stdpath("state") .. "/lazy/pkg_cache.lua",
        versions = true, -- Honor versions in pkg sources
        
        -- The first package source that is found for a plugin will be used.
        sources = {
            "lazy",
            "rockspec",
            "packspec",
        },
    },
    rocks = {
        root   = vim.fn.stdpath("data") .. "/lazy/rocks",
        server = "https://nvim-neorocks.github.io/rocks-binaries/",
    },
    install = {
        -- Install missing plugins on startup
        missing = true,
        
        -- Attempt to load colorscheme during installation 
        colorscheme = { "middlenight_blue" },
    },
    ui = {
        size = { width = 0.8, height = 0.8 },
        -- Line Wrapping
        wrap = true, 
        -- UI Floating Window Border
        border = "none",
        -- The backdrop opacity. 0 is fully opaque, 100 is fully transparent.
        backdrop = 40,
        
        -- Title,
        -- - If border not "none"
        title = nil, 
        title_pos = "center", ---@type "center" | "left" | "right"
        
        -- :Lazy Window Header Icons
        pills = true, ---@type boolean
        icons = {
            cmd = " ",
            config = "",
            event = " ",
            favorite = " ",
            ft = " ",
            init = " ",
            import = " ",
            keys = " ",
            lazy = "󰒲 ",
            loaded = "●",
            not_loaded = "○",
            plugin = " ",
            runtime = " ",
            require = "󰢱 ",
            source = " ",
            start = " ",
            task = "✔ ",
            list = {
                "●",
                "➜",
                "★",
                "‒",
            },
        },
        browser = "/usr/bin/firefox",
        throttle = 20,
        
        -- Keymapping
        -- - Shown in :Lazy help
        custom_keys = {
            ["<localleader>l"] = {
                function(plugin)
                    require("lazy.util").float_term({ "lazygit", "log" }, {
                        cwd = plugin.dir
                    })
                end,
                desc = "Open lazygit log",
            },
            ["<localleader>t"] = {
                function(plugin)
                    require("lazy.util").float_term(nil, {
                        cwd = plugin.dir
                    })
                end,
                desc = "Open terminal in plugin.dir"
            },
        },
        
    },
    diff = {
        -- diff command <d> can be one of:
        -- * browser: opens the github compare view. Note that this is always
		--     mapped to <K> as well, so you can have a different command for
		--     diff <d>
        -- * git: will run git diff and open a buffer with filetype git
        -- * terminal_git: will open a pseudo terminal with git diff
        -- * diffview.nvim: will open Diffview to show the diff
        cmd = "git",
    },
    checker = {
        -- [Disabled] Auto-Update Check 
        enabled = true,
        
        -- Concurrent/Parallel Check Limit
        concurrency = nil, ---@type number?
        notify = false,
        
        -- Check Frequency (seconds)
        frequency = 3600,
        
        -- Check Version Pinned Packages (requires manual plugin spec edit)
        check_pinned = false, 
    },
    change_detection = {
        -- Configuration File Modification
        enabled = true,
        notify  = false,
    },
    performance = {
        cache = { enabled = true, },
        reset_packpath = true, -- reset the package path to improve startup time
        rtp = {
            reset = true, -- reset the runtime path to $VIMRUNTIME and your config ctory
            ---@type string[]
            paths = {}, -- add any custom paths here that you want to includes in the rtp
            ---@type string[] list any plugins you want to disable here
            disabled_plugins = {
                -- "gzip",
                -- "matchit",
                -- "matchparen",
                -- "netrwPlugin",
                -- "tarPlugin",
                -- "tohtml",
                -- "tutor",
                -- "zipPlugin",
            },
        },
    },
    readme = {
        -- lazy can generate helptags from the headings in markdown readme files,
        -- so :help works even for plugins that don't have vim docs.
        -- when the readme opens with :help it will be correctly displayed as markdown
        enabled = true,
        root    = vim.fn.stdpath("data") .. "/lazy/readme",
        files   = { "README.md", "lua/**/README.md" },
        -- only generate markdown helptags for plugins that dont have docs
        skip_if_doc_exists = true,
    },
    profiling = {
        -- Enables extra stats on the debug tab related to the loader cache.
        -- Additionally gathers stats about all package.loaders
        loader = true,
        -- Track each new require in the Lazy profiling tab
        require = false,
    },
}

local install = function ()
    if not (vim.uv or vim.loop).fs_stat(lazypath) then
        local out = vim.fn.system({ 
            "git", 
            "clone", 
            "--filter=blob:none", 
            "--branch=stable", 
            "https://github.com/folke/lazy.nvim.git", 
            lazypath 
        })
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
end

lazy.setup = function ()
    install()
    vim.opt.rtp:append(lazypath)
    require("lazy").setup(spec, opts)
end

return lazy
