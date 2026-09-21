#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/mini.test.lua
--
--

---@module "lazy"

---@type LazyPluginSpec
local M = {
    "nvim-mini/mini.test",
    lazy = true,
    cmds = {}, -- See usercmds
}

M.opts = {
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
        -- referenced here only to satisfy selene's unused-arg check.
        filter_cases = function(case)
            return not not case
        end,
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
}

local usercmds = {
    {
        cmd = "Run",
        func = "run",
        desc = "Run all cases",
    },
    {
        cmd = "RunFile",
        func = "run_file",
        desc = "Run current file",
    },
    {
        cmd  = "RunAtCursor",
        func = "run_at_location",
        desc = "Run case at cursor",
    },
    {
        cmd = "Stop",
        func = "stop",
        desc = "Stop execution",
    },
}

for _, usercmd in ipairs(usercmds) do
    table.insert(M.cmds, "MiniTest" .. usercmd.cmd)
end

M.config = function()
    local MiniTest = require("mini.test")
    for _, usercmd in ipairs(usercmds) do
        vim.api.nvim_create_user_command(
            "MiniTest" .. usercmd.cmd,
            MiniTest[usercmd.func],
            { desc = "MiniTest: " .. usercmd.desc }
        )
    end
end

return M
