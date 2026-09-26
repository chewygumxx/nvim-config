#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_usercmd.lua
--
--

--
-- `usercmd.setup()` is the registry: every `XX*` command this config
-- offers exists because it is named here, and each one's `nargs`, `bang`
-- and `complete` are part of how it is invoked. A command dropped from
-- the list, or one whose delegate module fails to load, shows up as
-- nothing at all until someone types the name and gets E492.
--

local eq = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

--- Every command `usercmd.setup()` registers, with the options that make
--- each one usable: how many arguments it takes, whether it accepts a
--- bang, and whether it completes them.
---@type table<string, { nargs: string, bang: boolean, complete: boolean }>
local expected = {
    XXVisTrav         = { nargs = "0", bang = false, complete = false },
    XXVisTravToggle   = { nargs = "0", bang = false, complete = false },
    XXVisTravEnable   = { nargs = "0", bang = false, complete = false },
    XXVisTravDisable  = { nargs = "0", bang = false, complete = false },
    XXInterpretEscape = { nargs = "0", bang = true, complete = false },
    XXRedirAutocmd    = { nargs = "*", bang = true, complete = false },
    XXRedirCommand    = { nargs = "*", bang = true, complete = false },
    XXRedirHighlight  = { nargs = "*", bang = true, complete = false },
    XXRedirMap        = { nargs = "*", bang = true, complete = false },
    XXInsertHeader    = { nargs = "0", bang = false, complete = false },
    XXLuaChecker      = { nargs = "?", bang = false, complete = true },
    XXWip             = { nargs = "?", bang = true, complete = true },
    XXNexNote         = { nargs = "?", bang = false, complete = true },
    XXMdTable         = { nargs = "?", bang = false, complete = true },
}

--- The `:cnoreabbrev` shorthands registered alongside the `XXRedir*`
--- commands, mapping the Vim command each abbreviates.
---@type table<string, string>
local abbreviated = {
    autocmd   = "XXRedirAutocmd",
    command   = "XXRedirCommand",
    highlight = "XXRedirHighlight",
    map       = "XXRedirMap",
}

describe("usercmd.setup", function()
    ---@type table<string, vim.api.keyset.command_info>
    local commands

    before_each(function()
        require("usercmd").setup()
        commands = vim.api.nvim_get_commands({})
    end)

    after_each(function()
        for name in pairs(expected) do
            pcall(vim.api.nvim_del_user_command, name)
        end
        -- Left in place these would rewrite `:autocmd` and friends for
        -- every later case in the suite. Not wrapped in `pcall`: every
        -- one was just registered by `before_each`, so a missing
        -- abbreviation here is a failure worth hearing about.
        for vimcmd in pairs(abbreviated) do
            vim.cmd("cunabbrev " .. vimcmd)
        end
    end)

    it("registers every command it names", function()
        for name in pairs(expected) do
            eq({ name, commands[name] ~= nil }, { name, true })
        end
    end)

    it("registers each one's argument handling", function()
        for name, want in pairs(expected) do
            local info = assert(commands[name], name .. " is not registered")
            eq(
                { name, info.nargs, info.bang, info.complete ~= nil },
                { name, want.nargs, want.bang, want.complete }
            )
        end
    end)

    it("describes every command", function()
        -- The descriptions are what `:Telescope commands` and which-key
        -- show, so an empty one is a command nobody can discover
        for name in pairs(expected) do
            local info = assert(commands[name], name .. " is not registered")
            eq({ name, type(info.definition) }, { name, "string" })
            eq({ name, #info.definition > 0 }, { name, true })
        end
    end)

    it("abbreviates the pager-awkward Vim commands", function()
        local listed = vim.api.nvim_exec2("cabbrev", { output = true })
            .output
        for vimcmd, command in pairs(abbreviated) do
            eq(
                { vimcmd, listed:find(command, 1, true) ~= nil },
                { vimcmd, true }
            )
        end
    end)

    it("completes the arguments of the commands that take them", function()
        -- Asserted through the registered `complete` rather than the
        -- module behind it: the point is that the command is wired to
        -- the right one, which a typo in `usercmd.init` would break
        eq(
            vim.fn.getcompletion("XXWip ", "cmdline"),
            require("util.wip").complete()
        )
        eq(
            vim.fn.getcompletion("XXLuaChecker ", "cmdline"),
            require("util.lua_checker").checkers
        )
        eq(
            vim.fn.getcompletion("XXMdTable ", "cmdline"),
            require("util.markdown_table").complete()
        )
        eq(
            vim.fn.getcompletion("XXNexNote ", "cmdline"),
            require("util.nex").complete()
        )
    end)
end)
