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
-- in `lua/spec/mini.nvim.lua`), so this is the single entry point for
-- both `:XXTestRun` and headless CI invocations
-- (`nvim --headless -u init.lua -l scripts/minitest.lua`).
--

-- `require("mini.test")` is only guaranteed to resolve modules under this
-- repo's own `lua/` (e.g. `require("util.git")` from a test file) once its
-- root is on the runtime path; harmless to prepend again if already there.
vim.opt.rtp:prepend(vim.fn.getcwd())

local minitest = require("mini.test")
if _G.MiniTest == nil then
    minitest.setup()
end
minitest.run()
