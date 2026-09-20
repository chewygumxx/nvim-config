#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua foldlevel=1:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/mini.nvim.lua
--
--

--
--  https://github.com/nvim-mini/mini.nvim
--

---@module "lazy"
---@type LazySpec
local M = {
    "nvim-mini/mini.nvim",
    version = false, -- 'main' branch
}

local opts = {
    hipatterns = {
        highlighters = {},
    },
    icons = {},
    files = {
        -- Customization of shown content
        content = {
            -- Predicate for which file system entries to show
            filter = nil,
            -- What prefix to show to the left of file system entry
            prefix = nil,
            -- In which order to show file system entries
            sort = nil,
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
            -- Maximum number of windows to show side by side
            max_number = math.huge,
            -- Whether to show preview of file/directory under cursor
            preview = true,
            -- Width of focused window
            width_focus = 80,
            -- Width of non-focused window
            width_nofocus = 20,
            -- Width of preview window
            width_preview = 30,
        },
    },
    test = {
        -- Options for collection of test cases. See `:h MiniTest.collect()`.
        collect = {
            -- Temporarily emulate functions from 'busted' testing framework
            -- (`describe`, `it`, `before_each`, `after_each`, and more)
            emulate_busted = true,

            -- Function returning array of file paths to be collected.
            -- Default: all Lua files in 'tests' directory starting with 'test_'.
            find_files = function()
                return vim.fn.globpath("tests", "**/test_*.lua", true, true)
            end,

            -- Predicate function indicating if test case should be executed.
            -- Upstream default is `function(case) return true end`; case is
            -- referenced here only to satisfy luacheck's unused-arg check.
            filter_cases = function(case) return not not case end,
        },

        -- Options for execution of test cases. See `:h MiniTest.execute()`.
        execute = {
            -- Table with callable fields `start()`, `update()`, and `finish()`.
            -- `nil` auto-picks `gen_reporter.buffer()` interactively or
            -- `gen_reporter.stdout()` headlessly, which is what makes a
            -- single `scripts/minitest.lua` work both from `:MiniTest.run()`
            -- and from CI, without a plugin-specific override here.
            reporter = nil,

            -- Whether to stop execution after first error
            stop_on_error = false,
        },

        -- Path (relative to current directory) to script which handles project
        -- specific test running
        script_path = "scripts/minitest.lua",

        -- Whether to disable showing non-error feedback
        silent = false,
    },
}

--- Registers the `XXTest*` user commands, backed by `mini.test`. cwd-
--- relative, like `mini.test`'s own config, so they work unmodified in
--- whichever plugin repo is currently open, not just this config. `setup()`
--- is deferred to first invocation rather than paid on every startup: not
--- every session that wants `mini.hipatterns` is also running this repo's
--- test suite.
---@return nil
local mini_test_usercmds = function()
    local done = false
    ---@param method string
    local function run(method)
        return function()
            local mt = require("mini.test")
            if not done then
                mt.setup(opts.test)
                done = true
            end
            mt[method]()
        end
    end
    local usercmd = vim.api.nvim_create_user_command
    usercmd("XXTestRun", run("run"), { desc = "MiniTest: Run all cases" })
    usercmd("XXTestRunFile", run("run_file"), {
        desc = "MiniTest: Run current file",
    })
    usercmd("XXTestRunAtCursor", run("run_at_location"), {
        desc = "MiniTest: Run case at cursor",
    })
    usercmd("XXTestStop", run("stop"), { desc = "MiniTest: Stop execution" })
end

M.config = function()
    local hipatterns                       = require("mini.hipatterns")
    opts.hipatterns.highlighters.hex_color = hipatterns.gen_highlighter
        .hex_color({
            "line",                     -- <style>
            200,                        -- <priority>
            function() return true end, -- <filter>
            nil,
        })
    hipatterns.setup(opts.hipatterns)
    require("mini.icons").setup(opts.icons or {})
    require("mini.files").setup(opts.files or {})
    mini_test_usercmds()
end

return M
