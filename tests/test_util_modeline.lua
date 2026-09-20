#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_modeline.lua
--
--

local modeline = require("util.modeline")
local eq       = MiniTest.expect.equality

describe("util.modeline.base", function()
    it("builds a modeline from explicit options", function()
        eq(
            modeline.base({
                et = true,
                sw = 4,
                ft = "lua",
                commentstring = "-- %s",
            }),
            "-- vim:set expandtab shiftwidth=4 filetype=lua:"
        )
    end)

    it("elides expandtab when et is explicitly false", function()
        eq(
            modeline.base({
                et = false,
                sw = 2,
                ft = "markdown",
                commentstring = "# %s",
            }),
            "# vim:set shiftwidth=2 filetype=markdown:"
        )
    end)

    it("appends extra :set clauses verbatim", function()
        eq(
            modeline.base({
                et = false,
                sw = false,
                ft = "",
                commentstring = "%s",
                append = ":foldmethod=marker",
            }),
            "vim:set:foldmethod=marker:"
        )
    end)

    it("falls back to the buffer's own option values when unset", function()
        local buf                 = vim.api.nvim_create_buf(false, true)
        vim.bo[buf].expandtab     = true
        vim.bo[buf].shiftwidth    = 8
        vim.bo[buf].filetype      = "lua"
        vim.bo[buf].commentstring = "-- %s"

        eq(
            modeline.base({ buf = buf }),
            "-- vim:set expandtab shiftwidth=8 filetype=lua:"
        )

        vim.api.nvim_buf_delete(buf, { force = true })
    end)
end)
