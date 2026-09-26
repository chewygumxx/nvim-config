#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_usercmd_interpret_escape.lua
--
--

--
-- `XXInterpretEscape` turns the current buffer into a terminal rendering of
-- its own text, so that a captured log's escape codes are interpreted
-- rather than displayed.
--
-- Everything is asserted through a bang invocation. Without one the module
-- also writes a pre-interpretation copy under `stdpath("cache")`, which is
-- the machine's real cache directory: `stdpath` is fixed at startup and
-- cannot be redirected from here, and a test suite has no business leaving
-- files in it.
--
-- What is asserted is the structure the module installs, not the rendered
-- text. `nvim_chan_send` hands bytes to a terminal that draws them when it
-- gets round to it, so the text is a race; the keymap and the autocmds are
-- not.
--

local interpret_escape = require("usercmd.interpret_escape")
local eq               = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

describe("usercmd.interpret_escape.command", function()
    ---@type integer
    local bufnr

    ---@type integer
    local winid

    before_each(function()
        -- A window of its own, since the module acts on the current buffer
        -- and replaces it with a terminal
        vim.cmd("new")
        bufnr = vim.api.nvim_get_current_buf()
        winid = vim.api.nvim_get_current_win()
    end)

    after_each(function()
        if vim.api.nvim_win_is_valid(winid) then
            vim.api.nvim_win_close(winid, true)
        end
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
    end)

    --- Invokes the command with a bang against the fixture buffer.
    ---@param lines string[] Buffer text to interpret
    ---@return nil
    local interpret = function(lines)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.api.nvim_win_call(winid, function()
            ---@type vim.api.keyset.create_user_command.command_args
            ---@diagnostic disable-next-line: missing-fields
            local args = { bang = true, fargs = {} }
            interpret_escape.command(args)
        end)
    end

    it("turns the buffer into a terminal", function()
        interpret({ "\027[38:2::255:0:0mred\027[0m", "plain" })
        eq(vim.bo[bufnr].buftype, "terminal")
    end)

    it("maps q to quit in the rendered buffer", function()
        -- The buffer is a terminal afterwards, so the ordinary ways out of
        -- it do not apply and the mapping is the way out
        interpret({ "text" })

        ---@type string?
        local rhs
        for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "n")) do
            if map.lhs == "q" then
                ---@type string?
                local mapped = map.rhs
                rhs          = mapped
            end
        end
        eq(rhs, "<Cmd>qa!<CR>")
    end)

    it("follows the tail of the output and leaves insert mode", function()
        -- Both autocmds are buffer-local, so a second interpreted buffer
        -- does not inherit them
        interpret({ "text" })

        ---@type table<string, boolean>
        local events = {}
        for _, autocmd in ipairs(
            vim.api.nvim_get_autocmds({
                buffer = bufnr,
            })
        ) do
            ---@type string
            local event   = autocmd.event
            events[event] = true
        end

        eq(events.TextChanged, true)
        eq(events.TermEnter, true)
    end)

    it("writes nothing to the cache directory when banged", function()
        -- The one assertion that is about the bang itself: the copy under
        -- `stdpath("cache")/log-ansi/` is what a bangless call is for
        local log_dir = vim.fn.stdpath("cache") .. "/log-ansi/"
        local before  = vim.fn.glob(log_dir .. "*", false, true)

        interpret({ "text" })

        eq(vim.fn.glob(log_dir .. "*", false, true), before)
    end)
end)
