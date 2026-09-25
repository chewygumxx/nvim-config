#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/minitest.lua
--
--

--
-- This config's `mini.test` configuration, in the one place both of its
-- entry points can reach.
--
-- There are two, and they do not share a code path: lazy.nvim loads the
-- plugin and runs `lua/spec/mini.test.lua`'s `config()` in an interactive
-- session, while a headless run
-- (`nvim --headless -u scripts/minimal_init.lua -l scripts/minitest.lua`)
-- never loads lazy.nvim at all. Keeping the options in the spec is what
-- made them dead: lazy.nvim only calls `require(main).setup(opts)` when
-- `config` is *not* a function, and that spec's `config` is one, so the
-- table was never passed to anything. It agreed with `mini.test`'s own
-- defaults, which is why nothing looked wrong; the first edit that
-- disagreed with them, ie. widening `find_files` to a new test
-- directory, would have been silently ignored in both entry points.
--

local M = {}

---@type MiniTest.Config
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
        -- single `scripts/minitest.lua` work both from `MiniTest.run()`
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

--- Applies `M.opts` to `mini.test`.
---@return nil
M.setup = function()
    require("mini.test").setup(M.opts)
end

return M
