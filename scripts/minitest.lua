#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/scripts/minitest.lua
--
--

--
-- MiniTest's project-specific test runner: `MiniTest.run()` tries to
-- `luafile` this script before doing anything else (`opts.script_path`
-- in `lua/util/minitest.lua`), so this is the single entry point for
-- both `:MiniTestRun` and headless CI invocations
-- (nvim --headless -u scripts/minimal_init.lua -l scripts/minitest.lua).
--
-- Written to fail closed, for the same reason `scripts/luals_untyped.lua`
-- is: `mini.test` ends a run with `cquit 0` whenever nothing failed, and
-- a run that collected nothing has nothing to fail, so an empty
-- collection exits 0 and reports success to CI and `.husky/pre-commit`
-- alike. Everything collection depends on is relative to the current
-- directory (`find_files` globs "tests", the runtimepath surgery in
-- `scripts/minimal_init.lua` prepends `getcwd()`), so the wrong directory
-- is the likeliest way to reach that state, and a renamed test directory
-- or an edited glob is the next.
--
-- The checks raise rather than report: headlessly, under `-l`, that is a
-- non-zero exit. Interactively they are advisory, since `MiniTest.run()`
-- sources this script inside a `pcall` and quietly falls back to
-- collecting with its own configuration when it raises.
--

-- `require("mini.test")` is only guaranteed to resolve modules under this
-- repo's own `lua/` (e.g. `require("util.git")` from a test file) once its
-- root is on the runtime path; harmless to prepend again if already there.
vim.opt.rtp:prepend(vim.fn.getcwd())

--- A file every checkout of this repository has, at a path collection is
--- resolved against, so that its absence names the actual problem.
local anchor = "lua/util/minitest.lua"
if vim.fn.filereadable(anchor) == 0 then
    error(
        string.format(
            "run from the repository root: no %s under %s",
            anchor,
            vim.fn.getcwd()
        )
    )
end

-- Through `util.minitest` rather than `MiniTest.setup()` bare, so that a
-- headless run collects and executes by exactly the same configuration an
-- interactive `:MiniTestRun` does
local minitest = require("util.minitest")
minitest.setup()

---@type fun(): string[]
local find_files = assert(
    minitest.opts.collect and minitest.opts.collect.find_files,
    "util.minitest no longer configures collect.find_files"
)

local files = find_files()
if #files == 0 then
    error(
        string.format(
            "collected no test files under %s: nothing would have run",
            vim.fn.getcwd()
        )
    )
end

require("mini.test").run()
