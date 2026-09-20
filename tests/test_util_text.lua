#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_text.lua
--
--

local text = require("util.text")
local eq   = MiniTest.expect.equality

describe("util.text.wrap_comment", function()
    it(
        "packs words up to width, wrapping a %s-suffixed commentstring",
        function()
            eq(
                text.wrap_comment(
                    "one two three four five",
                    15,
                    { commentstring = "-- %s" }
                ),
                { "-- one two", "-- three four", "-- five" }
            )
        end
    )

    it(
        "right-pads the final line when commentstring has a trailing suffix",
        function()
            local lines = text.wrap_comment(
                "hi",
                10,
                { commentstring = "/* %s */" }
            )
            eq(#lines, 1)
            -- Padding brings the whole formatted line up to `width`.
            eq(#lines[1], 10)
            eq(lines[1]:match("^/%* hi%s+%*/$") ~= nil, true)
        end
    )

    it("never splits a single word, even past width", function()
        local lines = text.wrap_comment("supercalifragilistic", 10, {
            commentstring = "-- %s",
        })
        eq(lines, { "-- supercalifragilistic" })
    end)
end)
