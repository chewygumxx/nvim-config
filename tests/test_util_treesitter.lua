#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_treesitter.lua
--
--

--
-- The predicates only ever call `:range()`/`:prev_sibling()`/
-- `:next_sibling()` on nodes, plus the `:start()`/`:end_()` that
-- `vim.treesitter.get_node_text` needs for `M.last_matching`, and accept a
-- raw source string in place of a bufnr, so a real parsed buffer isn't
-- needed: a chain of duck-typed fake nodes exercises the same code paths.
--

local treesitter = require("util.treesitter")
---@type mini.test
local MiniTest = require("mini.test")
local eq       = MiniTest.expect.equality

--- Builds a chain of fake TSNode-like tables, one per spec.
---@param specs { row: integer, start_col: integer, end_col: integer } []
---@return table[] nodes
local function fake_chain(specs)
    ---@type table[]
    local nodes = {}
    for i, s in ipairs(specs) do
        -- `start`/`end_` answer the byte offset as well, which is what
        -- `vim.treesitter.get_node_text` slices a string source by. The
        -- column doubles as the offset, since every fixture is one line.
        nodes[i] = {
            range = function()
                return s.row, s.start_col, s.row, s.end_col
            end,
            start = function()
                return s.row, s.start_col, s.start_col
            end,
            end_ = function()
                return s.row, s.end_col, s.end_col
            end,
        }
    end
    for i, node in ipairs(nodes) do
        node.prev_sibling = function()
            return nodes[i - 1]
        end
        node.next_sibling = function()
            return nodes[i + 1]
        end
    end
    return nodes
end

describe("util.treesitter.adjacent", function()
    it("is true with fewer than two captured nodes", function()
        local nodes = fake_chain(
            { { row = 0, start_col = 0, end_col = 2 } }
        )
        eq(
            treesitter.adjacent(
                { ["@a"] = nodes },
                0,
                "ab",
                { "adjacent?", "@a" }
            ),
            true
        )
    end)

    it("is true when only whitespace separates same-row nodes", function()
        local nodes = fake_chain({
            { row = 0, start_col = 0, end_col = 2 },
            { row = 0, start_col = 4, end_col = 6 },
        })
        local match = { ["@a"] = { nodes[1] }, ["@b"] = { nodes[2] } }
        eq(
            treesitter.adjacent(
                match,
                0,
                "ab  cd",
                { "adjacent?", "@a", "@b" }
            ),
            true
        )
    end)

    it("is false when non-whitespace separates same-row nodes", function()
        local nodes = fake_chain({
            { row = 0, start_col = 0, end_col = 2 },
            { row = 0, start_col = 3, end_col = 5 },
        })
        local match = { ["@a"] = { nodes[1] }, ["@b"] = { nodes[2] } }
        eq(
            treesitter.adjacent(
                match,
                0,
                "ab-cd",
                { "adjacent?", "@a", "@b" }
            ),
            false
        )
    end)

    it("is false across different rows", function()
        local nodes = fake_chain({
            { row = 0, start_col = 0, end_col = 2 },
            { row = 1, start_col = 0, end_col = 2 },
        })
        local match = { ["@a"] = { nodes[1] }, ["@b"] = { nodes[2] } }
        eq(
            treesitter.adjacent(
                match,
                0,
                "ab\nab",
                { "adjacent?", "@a", "@b" }
            ),
            false
        )
    end)

    it("sorts captured nodes by position before checking gaps", function()
        -- "@a" resolves after "@b" here, deliberately out of source order.
        local nodes = fake_chain({
            { row = 0, start_col = 0, end_col = 2 },
            { row = 0, start_col = 4, end_col = 6 },
        })
        local match = { ["@a"] = { nodes[2] }, ["@b"] = { nodes[1] } }
        eq(
            treesitter.adjacent(
                match,
                0,
                "ab  cd",
                { "adjacent?", "@a", "@b" }
            ),
            true
        )
    end)
end)

describe("util.treesitter.last_matching", function()
    -- `queries/comment/highlights.scm` uses this to find the extension of
    -- a header's path: a word is the extension only if no later sibling
    -- is a word as well. "a.lua" is three nodes, "a", "." and "lua".
    local source = "a.lua"
    local words  = "^[%w_]+$"

    ---@return table[] nodes
    local path = function()
        return fake_chain({
            { row = 0, start_col = 0, end_col = 1 },
            { row = 0, start_col = 1, end_col = 2 },
            { row = 0, start_col = 2, end_col = 5 },
        })
    end

    --- Runs the predicate over one captured node.
    ---@param node table
    ---@return boolean
    local last = function(node)
        return treesitter.last_matching(
            { ["@a"] = { node } },
            0,
            source,
            { "last-matching?", "@a", words }
        )
    end

    it("is true for the last node whose siblings match", function()
        eq(last(path()[3]), true)
    end)

    it("is false when a later sibling matches too", function()
        -- "." does not match, but "lua" after it does
        eq(last(path()[1]), false)
    end)

    it("is true when the capture is absent", function()
        eq(
            treesitter.last_matching(
                {},
                0,
                source,
                { "last-matching?", "@a", words }
            ),
            true
        )
    end)
end)

describe("util.treesitter.header_line", function()
    it("matches a repo-slug header line", function()
        local source = "~chewygumxx/nvim-config.git"
        local nodes  = fake_chain({
            { row = 0, start_col = 0, end_col = 1 },
            { row = 0, start_col = 1, end_col = #source },
        })
        local match  = { ["@a"] = { nodes[1] } }
        eq(
            treesitter.header_line(match, 0, source, { "header-line?", "@a" }),
            true
        )
    end)

    it("matches a repo-path header line", function()
        local source = "::: :/lua/util/treesitter.lua"
        local nodes  = fake_chain({
            { row = 0, start_col = 0, end_col = #source },
        })
        local match  = { ["@a"] = { nodes[1] } }
        eq(
            treesitter.header_line(
                match,
                0,
                source,
                { "header-line?", "@a", "path" }
            ),
            true
        )
    end)

    it(
        "rejects a path-shaped line when restricted to the repo shape",
        function()
            local source = "::: :/lua/util/treesitter.lua"
            local nodes  = fake_chain({
                { row = 0, start_col = 0, end_col = #source },
            })
            local match  = { ["@a"] = { nodes[1] } }
            eq(
                treesitter.header_line(
                    match,
                    0,
                    source,
                    { "header-line?", "@a", "repo" }
                ),
                false
            )
        end
    )

    it("rejects a line matching neither header shape", function()
        local source = "just a regular comment"
        local nodes  = fake_chain({
            { row = 0, start_col = 0, end_col = #source },
        })
        local match  = { ["@a"] = { nodes[1] } }
        eq(
            treesitter.header_line(match, 0, source, { "header-line?", "@a" }),
            false
        )
    end)

    it("is true when the capture is absent from match", function()
        eq(
            treesitter.header_line(
                {},
                0,
                "irrelevant",
                { "header-line?", "@a" }
            ),
            true
        )
    end)
end)
