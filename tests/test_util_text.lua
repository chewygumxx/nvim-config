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
---@type mini.test
local MiniTest = require("mini.test")
local eq       = MiniTest.expect.equality

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

describe("util.text.yaml_scalar", function()
    -- The quoting rule `util.header.frontmatter` and `util.nex` share, so
    -- that one `title:` or tag cannot be quoted two ways.

    it("leaves a plain scalar unquoted", function()
        eq(text.yaml_scalar("Some Note Title"), "Some Note Title")
    end)

    it("quotes what would be ambiguous or invalid YAML", function()
        eq(text.yaml_scalar("Title: with a colon"), '"Title: with a colon"')
        eq(text.yaml_scalar("- leading dash"), '"- leading dash"')
        eq(text.yaml_scalar("trailing space "), '"trailing space "')
        eq(text.yaml_scalar(""), '""')
    end)

    it("escapes quotes and backslashes when quoting", function()
        eq(text.yaml_scalar('a "b" \\ c'), '"a \\"b\\" \\\\ c"')
    end)
end)
