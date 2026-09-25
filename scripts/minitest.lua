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

-- `require("mini.test")` is only guaranteed to resolve modules under this
-- repo's own `lua/` (e.g. `require("util.git")` from a test file) once its
-- root is on the runtime path; harmless to prepend again if already there.
vim.opt.rtp:prepend(vim.fn.getcwd())

-- Through `util.minitest` rather than `MiniTest.setup()` bare, so that a
-- headless run collects and executes by exactly the same configuration an
-- interactive `:MiniTestRun` does
require("util.minitest").setup()
require("mini.test").run()
