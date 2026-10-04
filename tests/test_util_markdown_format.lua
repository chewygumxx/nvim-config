#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_markdown_format.lua
--
--

local format   = require("util.markdown_format")
local markdown = require("filetype.markdown")
---@type mini.test
local MiniTest = require("mini.test")
local eq       = MiniTest.expect.equality

---@type integer
local bufnr

--- The buffer-local options of `filetype.markdown` that formatting reads.
---@type string[]
local formatting = { "autoindent", "comments", "formatexpr", "formatlistpat" }

--- Ten words, long enough to need wrapping at the width these tests set.
---@type string
local words = ("word "):rep(10):gsub(" $", "")

--- Opens a scratch Markdown buffer holding lines, with `filetype.markdown`'s
--- own formatting options and a narrow 'textwidth'.
---@param lines string[]
---@return nil
local open = function(lines)
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    for _, option in ipairs(formatting) do
        vim.api.nvim_set_option_value(option, markdown.local_opts[option], {
            buf = bufnr,
        })
    end
    vim.bo[bufnr].formatoptions = "tcqln"
    vim.bo[bufnr].textwidth     = 30
end

---@return string[]
local contents = function()
    return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

describe("util.markdown_format.runs", function()
    it("splits a range around the protected lines", function()
        eq(format.runs({ { first = 3, last = 4 } }, 1, 6), {
            { first = 1, last = 2 },
            { first = 5, last = 6 },
        })
    end)

    it("returns nothing for a range wholly protected", function()
        eq(format.runs({ { first = 1, last = 9 } }, 2, 5), {})
    end)
end)

describe("util.markdown_format.protected", function()
    after_each(function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("finds frontmatter, fences, tables and HTML blocks", function()
        open({
            "---",
            "title: T",
            "---",
            "",
            "Prose.",
            "",
            "```lua",
            "x()",
            "```",
            "",
            "| a |",
            "| - |",
            "",
            "<!--",
            "  - box",
            "  -->",
        })
        eq(format.protected(bufnr), {
            { first = 1, last = 3 },
            { first = 7, last = 9 },
            { first = 11, last = 12 },
            { first = 14, last = 16 },
        })
    end)

    it("falls back to a line scan without a parser", function()
        open({ "---", "a: b", "---", "", "~~~", "x", "~~~", "", "```" })
        local real = vim.treesitter.get_parser
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.treesitter.get_parser = function()
            return nil
        end
        local ranges              = format.protected(bufnr)
        vim.treesitter.get_parser = real
        -- The unclosed fence on the last line runs to the end
        eq(ranges, {
            { first = 1, last = 3 },
            { first = 5, last = 7 },
            { first = 9, last = 9 },
        })
    end)
end)

describe("util.markdown_format.formatexpr", function()
    after_each(function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("hangs a continuation line past the whole list marker", function()
        open({ "- " .. words, "- [ ] " .. words, "1. " .. words })
        vim.cmd("silent normal! gggqG")
        eq(contents(), {
            "- word word word word word",
            "  word word word word word",
            "- [ ] word word word word word",
            "      word word word word word",
            "1. word word word word word",
            "   word word word word word",
        })
    end)

    it("leaves a fenced code block exactly as written", function()
        local code = "local x = 1 -- " .. words
        open({ words, "", "```lua", code, "```", "", words })
        vim.cmd("silent normal! gggqG")
        local lines = contents()
        eq(vim.tbl_contains(lines, code), true)
        eq(vim.tbl_contains(lines, "```lua"), true)
        eq(lines[1], "word word word word word word")
        eq(lines[#lines], "word word word word")
    end)

    it("leaves frontmatter exactly as written", function()
        local title = "title: " .. words
        open({ "---", title, "---", "", words })
        vim.cmd("silent normal! gggqG")
        eq(contents()[2], title)
    end)

    it("does not auto-wrap a line typed inside a fence", function()
        open({ "```", "", "```" })
        vim.api.nvim_win_set_cursor(0, { 2, 0 })
        vim.api.nvim_feedkeys("A" .. words .. "\27", "xt", false)
        eq(contents()[2], words)
    end)

    it("auto-wraps prose typed outside one", function()
        open({ "" })
        vim.api.nvim_feedkeys("A- [ ] " .. words .. "\27", "xt", false)
        eq(#contents() > 1, true)
        eq(contents()[2]:match("^ *"), "      ")
    end)
end)
