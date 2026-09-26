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
    lazy = true, -- See M.cmd

    -- Pinned, and pinned *here*, because this is the one copy of mini.test
    -- both entry points share. `.github/workflows/test.yaml` reads this tag
    -- out of this file rather than naming its own: unpinned locally and
    -- pinned in CI, the pre-commit gate and CI could disagree about the
    -- test framework itself, which this machine already did (v0.18.0-5
    -- against CI's v0.18.0). https://github.com/nvim-mini/mini.test/tags
    tag = "v0.18.0",
}

-- The configuration itself lives in `lua/util/minitest.lua`, not in an
-- `M.opts` here: a spec whose `config` is a function never gets its opts
-- applied by lazy.nvim, and the headless runner does not go through
-- lazy.nvim at all. See that module's header.

local usercmds = {
    {
        cmd  = "Run",
        func = "run",
        desc = "Run all cases",
    },
    {
        cmd  = "RunFile",
        func = "run_file",
        desc = "Run current file",
    },
    {
        cmd  = "RunAtCursor",
        func = "run_at_location",
        desc = "Run case at cursor",
    },
    {
        cmd  = "Stop",
        func = "stop",
        desc = "Stop execution",
    },
}

---@type string[]
local cmds = {}
for _, usercmd in ipairs(usercmds) do
    table.insert(cmds, "MiniTest" .. usercmd.cmd)
end
M.cmd = cmds

M.config = function()
    require("util.minitest").setup()

    local MiniTest = require("mini.test") --[[@as mini.test]]
    for _, usercmd in ipairs(usercmds) do
        vim.api.nvim_create_user_command(
            "MiniTest" .. usercmd.cmd,
            MiniTest[usercmd.func],
            { desc = "MiniTest: " .. usercmd.desc }
        )
    end
end

return M
