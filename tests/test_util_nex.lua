#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_nex.lua
--
--

local nex = require("util.nex")
local eq  = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

--- Index of the first line in lines equal to needle, if any.
---@param lines  string[]
---@param needle string
---@return integer?
local index_of = function(lines, needle)
    for idx, line in ipairs(lines) do
        if line == needle then
            return idx
        end
    end
    return nil
end

describe("util.nex", function()
    ---@type cgxx.nex.Note
    local note

    before_each(function()
        note = {
            title       = "Some Note Title",
            description = "A short description.",
            tags        = { "draft", "nvim" },
            ctime       = "2026-09-26",
        }
    end)

    it("slugifies a title into lowercase hyphenated words", function()
        eq(nex.slugify("Some Note Title"), "some-note-title")
    end)

    it("collapses punctuation runs and trims edge hyphens", function()
        eq(nex.slugify("  Hello, World! -- (again)  "), "hello-world-again")
    end)

    it("slugifies a title with no alphanumerics to an empty string", function()
        eq(nex.slugify("!!! ???"), "")
    end)

    it("builds the filename from ctime, slug and extension", function()
        eq(nex.filename(note), "2026-09-26-some-note-title.note.md")
    end)

    it("defaults ctime to today when the note omits it", function()
        note.ctime = nil
        eq(
            nex.filename(note):sub(1, 10),
            tostring(os.date("%Y-%m-%d"))
        )
    end)

    it("builds the absolute path under the note subdirectory", function()
        eq(
            nex.path(note),
            nex.root .. "/note/2026-09-26-some-note-title.note.md"
        )
    end)

    it("leaves a plain title unquoted as a YAML scalar", function()
        eq(nex.yaml_scalar("Some Note Title"), "Some Note Title")
    end)

    it("quotes a title that would be ambiguous YAML", function()
        eq(nex.yaml_scalar("Title: with a colon"), '"Title: with a colon"')
        eq(nex.yaml_scalar("- leading dash"), '"- leading dash"')
        eq(nex.yaml_scalar(""), '""')
    end)

    it("escapes quotes and backslashes when quoting", function()
        eq(nex.yaml_scalar('a "b" \\ c'), '"a \\"b\\" \\\\ c"')
    end)

    it("renders frontmatter delimiters and the __cgxx block", function()
        local lines = nex.render(note)
        eq(lines[1], "---")
        eq(lines[2], "__cgxx: |")
        eq(
            lines[3],
            "  # vim:set expandtab shiftwidth=2 "
                .. "filetype=markdown.nex-note foldlevel=3:"
        )
    end)

    it("renders the boxed repo slug and root-relative path", function()
        local lines = nex.render(note)
        eq(index_of(lines, "  # ~chewygumxx/nex.git") ~= nil, true)
        eq(
            index_of(
                lines,
                "  # ::: :/note/2026-09-26-some-note-title.note.md"
            ) ~= nil,
            true
        )
    end)

    it("renders ctime, title and a folded description", function()
        local lines = nex.render(note)
        eq(index_of(lines, "ctime: 2026-09-26") ~= nil, true)
        eq(index_of(lines, "title: Some Note Title") ~= nil, true)
        local desc = index_of(lines, "description: >-")
        eq(desc ~= nil, true)
        eq(lines[desc + 1], "  A short description.")
    end)

    it("renders an empty description as an empty flow scalar", function()
        note.description = ""
        local lines      = nex.render(note)
        eq(index_of(lines, 'description: ""') ~= nil, true)
        eq(index_of(lines, "description: >-"), nil)
    end)

    it("wraps a long description at 80 columns including indent", function()
        note.description = string.rep("word ", 60)
        local lines      = nex.render(note)
        local desc       = index_of(lines, "description: >-")
        eq(desc ~= nil, true)
        for idx = desc + 1, #lines, 1 do
            if lines[idx]:sub(1, 2) ~= "  " or lines[idx]:match("^  %-") then
                break
            end
            eq(#lines[idx] <= 80, true)
            eq(lines[idx]:sub(1, 2), "  ")
        end
    end)

    it("renders a tag list as a YAML block sequence", function()
        local lines = nex.render(note)
        local tags  = index_of(lines, "tags:")
        eq(tags ~= nil, true)
        eq(lines[tags + 1], "  - draft")
        eq(lines[tags + 2], "  - nvim")
    end)

    it("renders an empty tag list as an empty flow sequence", function()
        note.tags   = {}
        local lines = nex.render(note)
        eq(index_of(lines, "tags: []") ~= nil, true)
        eq(index_of(lines, "tags:"), nil)
    end)

    it("closes the frontmatter and opens with a heading 1", function()
        local lines = nex.render(note)
        eq(lines[#lines - 4], "---")
        eq(lines[#lines - 3], "")
        eq(lines[#lines - 2], "# Some Note Title")
    end)

    it("ends on a blank line separated from the heading", function()
        local lines = nex.render(note)
        eq(lines[#lines - 1], "")
        eq(lines[#lines], "")
    end)

    it("leaves no trailing whitespace on any rendered line", function()
        for _, line in ipairs(nex.render(note)) do
            eq(line:match("[ \t]$"), nil)
        end
    end)

    it("reports a non-existent root as not a worktree", function()
        local root = nex.root
        nex.root   = vim.fn.tempname() .. "/absent"
        eq(nex.is_worktree(), false)
        nex.root = root
    end)

    it("reports a real git worktree as one", function()
        local root = nex.root
        local dir  = vim.fn.tempname()
        vim.fn.mkdir(dir, "p")
        vim.system({ "git", "-C", dir, "init", "--quiet" }):wait()

        nex.root = dir
        eq(nex.is_worktree(), true)

        nex.root = root
        vim.fn.delete(dir, "rf")
    end)

    it("reports a plain directory as not a worktree", function()
        local root = nex.root
        local dir  = vim.fn.tempname()
        vim.fn.mkdir(dir, "p")

        nex.root = dir
        eq(nex.is_worktree(), false)

        nex.root = root
        vim.fn.delete(dir, "rf")
    end)
end)
