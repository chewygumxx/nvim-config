#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_frontmatter.lua
--
--

local frontmatter = require("util.frontmatter")
---@type mini.test
local MiniTest = require("mini.test")
local eq       = MiniTest.expect.equality

---@type cgxx.test.helpers
local helpers = dofile("tests/helpers.lua")

--- The frontmatter a document carries unless a case gives its own.
---@type string[]
local default_fields = {
    "mtime: 2026-01-01",
    "title: Old",
    "description:",
    "tags:",
}

--- A document in the shape `util.header.frontmatter` renders.
---@param fields? string[] Frontmatter lines between ctime and the close
---@param body?   string[] Everything after the box
---@return string[] lines
local document = function(fields, body)
    ---@type string[]
    local lines = { "---", "ctime: 2026-01-01" }
    vim.list_extend(lines, fields or default_fields)
    vim.list_extend(lines, {
        "---",
        "",
        "<!--",
        "   -",
        "   - ~old/repo.git",
        "   - ::: :/old.md",
        "   -",
        "   -->",
        "",
    })
    vim.list_extend(lines, body or { "# New title", "", "Text." })
    return lines
end

---@type util.HeaderLocation
local location = { slug = "o/r", path = ":/notes/new.md" }

describe("util.frontmatter.close", function()
    it("finds the close of a dated frontmatter", function()
        eq(frontmatter.close(document()), 7)
    end)

    it("ignores frontmatter with no ctime", function()
        eq(frontmatter.close({ "---", "title: x", "---" }), nil)
    end)

    it("ignores a document that does not open on frontmatter", function()
        eq(frontmatter.close({ "# Title", "---" }), nil)
    end)
end)

describe("util.frontmatter.heading", function()
    it("takes the first level-one heading", function()
        eq(frontmatter.heading({ "## Two", "# One ##", "# Later" }, {}), "One")
    end)

    it("skips a heading inside a protected block", function()
        eq(
            frontmatter.heading({ "```", "# not", "```", "# Real" }, {
                { first = 1, last = 3 },
            }),
            "Real"
        )
    end)
end)

describe("util.frontmatter.unquote", function()
    it("unquotes either quoting style", function()
        eq(frontmatter.unquote('"a \\"b\\""'), 'a "b"')
        eq(frontmatter.unquote("'it''s'"), "it's")
        eq(frontmatter.unquote("plain"), "plain")
    end)

    it("declines block scalars, collections and an empty value", function()
        eq(frontmatter.unquote(">-"), nil)
        eq(frontmatter.unquote("|"), nil)
        eq(frontmatter.unquote("[a]"), nil)
        eq(frontmatter.unquote(""), nil)
    end)
end)

describe("util.frontmatter.sync", function()
    it("follows the heading, the date and the location", function()
        local lines        = document()
        local header, last = frontmatter.sync(
            lines,
            7,
            { { first = 1, last = 7 }, { first = 9, last = 14 } },
            location,
            "2026-10-05"
        )
        eq(last, 14)
        eq(header, {
            "---",
            "ctime: 2026-01-01",
            "mtime: 2026-10-05",
            "title: New title",
            "description:",
            "tags:",
            "---",
            "",
            "<!--",
            "   -",
            "   - ~o/r.git",
            "   - ::: :/notes/new.md",
            "   -",
            "   -->",
        })
    end)

    it("adds mtime beneath ctime when it is missing", function()
        local lines  = document({ "title: Old" })
        local header = frontmatter.sync(lines, 4, {}, nil, "2026-10-05")
        eq(vim.list_slice(header, 2, 4), {
            "ctime: 2026-01-01",
            "mtime: 2026-10-05",
            "title: New title",
        })
    end)

    it("folds a description too long for one line", function()
        local long   = string.rep("word ", 20):gsub(" $", "")
        local lines  = document({ "mtime: x", 'description: "' .. long .. '"' })
        local header = frontmatter.sync(lines, 5, {}, nil, "2026-10-05")
        eq(header[4], "description: >-")
        eq(header[5]:sub(1, 2), "  ")
    end)

    it("folds a short description YAML would need quoted", function()
        local lines  = document({ "mtime: x", "description: a: b" })
        local header = frontmatter.sync(lines, 5, {}, nil, "2026-10-05")
        eq(vim.list_slice(header, 4, 5), { "description: >-", "  a: b" })
    end)

    it("leaves a title alone when there is no heading", function()
        local lines  = document(nil, { "Text." })
        local header = frontmatter.sync(lines, 7, {}, nil, "2026-10-05")
        eq(header[4], "title: Old")
    end)

    it("leaves the box alone without a location", function()
        local lines        = document()
        local header, last = frontmatter.sync(lines, 7, {}, nil, "2026-10-05")
        eq(last, 7)
        eq(#header, 7)
    end)
end)

describe("util.frontmatter.autocmd", function()
    ---@type string
    local dir
    ---@type integer
    local bufnr

    before_each(function()
        dir = helpers.repo({ branch = "fm-test" })
        frontmatter.autocmd()
    end)

    after_each(function()
        vim.api.nvim_del_augroup_by_name("cgxx.frontmatter")
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
        vim.fn.delete(dir, "rf")
    end)

    it("syncs a modified Markdown buffer as it is written", function()
        local path = dir .. "/renamed.md"
        vim.fn.writefile(document(), path)
        vim.cmd.edit(vim.fn.fnameescape(path))
        bufnr                  = vim.api.nvim_get_current_buf()
        vim.bo[bufnr].filetype = "markdown"

        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "More." })
        vim.cmd("silent write")

        local written = vim.fn.readfile(path)
        eq(written[3], "mtime: " .. os.date("%Y-%m-%d"))
        eq(written[4], "title: New title")
        eq(written[12], "   - ::: :/renamed.md")
    end)

    it("leaves an unmodified buffer untouched", function()
        local path = dir .. "/same.md"
        vim.fn.writefile(document(), path)
        vim.cmd.edit(vim.fn.fnameescape(path))
        bufnr                  = vim.api.nvim_get_current_buf()
        vim.bo[bufnr].filetype = "markdown"

        vim.cmd("silent write")
        eq(vim.fn.readfile(path), document())
    end)
end)
