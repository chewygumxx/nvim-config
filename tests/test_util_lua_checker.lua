#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_lua_checker.lua
--
--

--
-- `util.lua_checker` holds which type checker nvim-lint runs for "lua",
-- and `usercmd.lua_checker` is the `XXLuaChecker` command over it. Both
-- work without nvim-lint present, which is what these cases run against:
-- the module degrades to bookkeeping when `require("lint")` fails, and
-- that degradation is the part a test can actually pin.
--

local checker = require("util.lua_checker")
local eq      = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

describe("util.lua_checker", function()
    ---@type string
    local original

    ---@type fun(msg: string, level?: integer, opts?: table)
    local notify

    ---@type string[]
    local notified

    before_each(function()
        original = checker.active
        notified = {}
        notify   = vim.notify
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function(msg)
            notified[#notified + 1] = msg
        end
    end)

    after_each(function()
        vim.notify = notify
        -- Module state, not session state, but just as shared: the whole
        -- suite runs in one process
        checker.active = original
    end)

    it("defaults to luals_check", function()
        eq(checker.active, "luals_check")
        eq(checker.checkers, { "luals_check", "emmylua_check" })
    end)

    it("runs selene alongside the active checker", function()
        -- selene is the linter proper and always runs; only the type
        -- checker beside it is switchable
        eq(checker.linters(), { "selene", "luals_check" })

        checker.set("emmylua_check")
        eq(checker.linters(), { "selene", "emmylua_check" })
    end)

    it("switches to a named checker", function()
        checker.set("emmylua_check")
        eq(checker.active, "emmylua_check")
    end)

    it("refuses an unknown name, leaving the active one", function()
        checker.set("shellcheck")
        eq(checker.active, "luals_check")
        eq(#notified, 1)
        eq(notified[1]:find("Unknown lua checker: shellcheck", 1, true), 1)
    end)

    it("toggles round the known checkers", function()
        checker.toggle()
        eq(checker.active, "emmylua_check")
        checker.toggle()
        eq(checker.active, "luals_check")
    end)

    it("toggles to the first checker from an unknown state", function()
        -- Nothing sets `active` to an unlisted value today, but the
        -- wrap-around is written to recover rather than get stuck
        checker.active = "something-else"
        checker.toggle()
        eq(checker.active, "luals_check")
    end)
end)

describe("usercmd.lua_checker", function()
    ---@type string
    local original

    ---@type fun(msg: string, level?: integer, opts?: table)
    local notify

    before_each(function()
        original = checker.active
        notify   = vim.notify
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function() end
    end)

    after_each(function()
        vim.notify     = notify
        checker.active = original
    end)

    --- Invokes the command callback with fargs. Only the field the
    --- callback reads is supplied, hence the cast.
    ---@param fargs string[]
    ---@return nil
    local invoke = function(fargs)
        ---@type vim.api.keyset.create_user_command.command_args
        ---@diagnostic disable-next-line: missing-fields
        local args = { fargs = fargs }
        require("usercmd.lua_checker").command(args)
    end

    it("sets the checker named in its argument", function()
        invoke({ "emmylua_check" })
        eq(checker.active, "emmylua_check")
    end)

    it("toggles when called bare", function()
        invoke({})
        eq(checker.active, "emmylua_check")
    end)

    it("completes the known checkers", function()
        eq(require("usercmd.lua_checker").complete(), checker.checkers)
    end)
end)
