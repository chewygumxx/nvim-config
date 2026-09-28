#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_vimdoc.lua
--
--

--
-- `util.vimdoc` is pure, so nothing here needs a fixture, a child process
-- or a restore step: every case is a call and a comparison. What it does
-- need is arithmetic asserted rather than eyeballed, since a tag one
-- column out of true is invisible in a diff and obvious in a help window.
--

local vimdoc = require("util.vimdoc")
---@type mini.test
local MiniTest = require("mini.test")
local eq       = MiniTest.expect.equality

describe("util.vimdoc.flush_right", function()
    it("ends the line exactly at the help width", function()
        local line = vimdoc.flush_right("KEYMAPS", "nvim-config-keymaps")
        eq(#line, vimdoc.width)
        eq(line:sub(1, 7), "KEYMAPS")
        eq(line:sub(-21), "*nvim-config-keymaps*")
    end)

    it("keeps one space when the tag would otherwise collide", function()
        local long = string.rep("x", vimdoc.width)
        eq(vimdoc.flush_right(long, "t"), long .. " *t*")
    end)

    -- The header box carries "└─>" for a fork, which is three cells and
    -- seven bytes; counting bytes would short the padding by four
    it("counts screen cells rather than bytes", function()
        eq(#vimdoc.flush_right("└─>", "t") > vimdoc.width, true)
        eq(
            vim.fn.strdisplaywidth(vimdoc.flush_right("└─>", "t")),
            vimdoc.width
        )
    end)
end)

describe("util.vimdoc.rule", function()
    it("spans the full help width", function()
        eq(vimdoc.rule("="), string.rep("=", vimdoc.width))
    end)
end)

describe("util.vimdoc.entry", function()
    it("joins a short lhs to its description at the gutter", function()
        eq(vimdoc.entry({ lhs = "<leader>ac", desc = "Toggle Claude" }), {
            "<leader>ac" .. string.rep(" ", vimdoc.indent - 10)
                .. "Toggle Claude",
        })
    end)

    it("drops a long lhs onto its own line", function()
        local lhs   = string.rep("x", vimdoc.indent)
        local lines = vimdoc.entry({ lhs = lhs, desc = "Short" })
        eq(lines[1], lhs)
        eq(lines[2], string.rep(" ", vimdoc.indent) .. "Short")
    end)

    it("hangs a wrapped description at the gutter", function()
        local lines = vimdoc.entry({
            lhs  = ":XXWip",
            desc = string.rep("word ", 40),
        })
        eq(#lines > 1, true)
        for i = 1, #lines, 1 do
            eq(#lines[i] <= vimdoc.width, true)
            if i > 1 then
                eq(
                    lines[i]:sub(1, vimdoc.indent),
                    string.rep(" ", vimdoc.indent)
                )
            end
        end
    end)

    it("emits a tag on its own line above the entry", function()
        local lines = vimdoc.entry({
            lhs  = ":XXWip",
            desc = "Snapshots",
            tag  = "nvim-config-wip",
        })
        eq(#lines[1], vimdoc.width)
        eq(lines[1]:match("^%s*(%S+)$"), "*nvim-config-wip*")
        eq(lines[2]:sub(1, 6), ":XXWip")
    end)

    -- A mapping this config declares with no description is still worth
    -- listing; `wrap_comment` would otherwise render a line of bare gutter
    it("renders a bare lhs when there is no description", function()
        eq(vimdoc.entry({ lhs = "gx" }), { "gx" })
    end)
end)

describe("util.vimdoc.fit", function()
    it("leaves a line that already fits alone", function()
        eq(vimdoc.fit({ "short", "" }, "  "), { "short", "" })
    end)

    -- The case `wrap_comment` cannot serve: 'statusline' is one token of
    -- close to two hundred characters, and there is no space to break at
    it("breaks an unbreakable token at the width", function()
        -- 161 characters over a four-space continuation indent: 78, then
        -- 4 + 74, then the 9 that are left
        local token = string.rep("x", vimdoc.width * 2 + 5)
        local lines = vimdoc.fit({ token }, "    ")
        eq(#lines, 3)
        eq(#lines[1], vimdoc.width)
        eq(#lines[2], vimdoc.width)
        eq(lines[2]:sub(1, 4), "    ")
        eq(lines[3], "    " .. string.rep("x", 9))
        -- Parenthesised: `gsub` returns a count as its second value, which
        -- would otherwise arrive as a third argument to `eq`
        eq((table.concat(lines):gsub(" ", "")), token)
    end)

    -- Breaking by character count would overshoot here, since each of
    -- these is one character and two cells
    it("breaks on screen cells rather than characters", function()
        local wide  = string.rep("あ", vimdoc.width)
        local lines = vimdoc.fit({ wide }, "")
        for _, line in ipairs(lines) do
            eq(vim.fn.strdisplaywidth(line) <= vimdoc.width, true)
        end
    end)

    -- The regression: a tail short enough to fit on its own line is not
    -- short enough to fit beneath the gutter, and counting it alone let a
    -- 99-column line into the generated 'statusline' entry
    it("counts the continuation indent against the remainder", function()
        local gutter = string.rep(" ", vimdoc.indent)
        local token  = string.rep("x", vimdoc.width + 60)
        for _, line in ipairs(vimdoc.fit({ token }, gutter)) do
            eq(#line <= vimdoc.width, true)
        end
    end)

    it("cannot spin when the indent leaves no room", function()
        local lines = vimdoc.fit({ "abc" }, string.rep(" ", vimdoc.width + 10))
        eq(#lines > 0, true)
    end)
end)

describe("util.vimdoc.contents", function()
    it("right-aligns every link and fills the gap with dots", function()
        local lines = vimdoc.contents({
            { title = "KEYMAPS", tag = "nvim-config-keymaps" },
            { title = "COMMANDS", tag = "nvim-config-commands" },
        })
        eq(#lines, 2)
        for _, line in ipairs(lines) do
            eq(#line, vimdoc.width)
            eq(line:sub(-1), "|")
            eq(line:find("%.%.%.") ~= nil, true)
        end
        eq(lines[1]:sub(1, 14), "    1. KEYMAPS")
    end)
end)

describe("util.vimdoc.render", function()
    ---@return string[] lines
    local rendered = function()
        return vimdoc.render({
            file    = "nvim-config.txt",
            tagline = "Configuration reference",
            slug    = "chewygumxx/nvim-config",
            -- `:/`-prefixed, as `util.git.path` returns it: the box reads
            -- `::: :/doc/nvim-config.txt`, not `::: /doc/...`
            path      = ":/doc/nvim-config.txt",
            spdx      = "GPL-3.0-only",
            generator = "scripts/genhelp.lua",
            sections  = {
                {
                    title   = "KEYMAPS",
                    tag     = "nvim-config-keymaps",
                    intro   = "Every mapping this configuration declares.",
                    entries = {
                        { lhs = "<leader>ac", desc = "Toggle Claude" },
                    },
                },
            },
        })
    end

    -- The modeline has to sit inside the first five lines, which is where
    -- Vim reads one from, and it has to be the expanded `set` form this
    -- repository writes everywhere else
    it("opens with the header modeline", function()
        eq(
            rendered()[1],
            "# vim:set textwidth=78 tabstop=8 filetype=help:"
        )
    end)

    it("carries the SPDX line and the boxed repository notation", function()
        local lines = table.concat(rendered(), "\n")
        eq(
            lines:find("# SPDX-License-Identifier: GPL-3.0-only", 1, true) ~= nil,
            true
        )
        eq(lines:find("# ~chewygumxx/nvim-config.git", 1, true) ~= nil, true)
        eq(lines:find("# ::: :/doc/nvim-config.txt", 1, true) ~= nil, true)
    end)

    -- The one tag a help file writes flush left, beside its description,
    -- rather than flush right like every other
    it("names its own tag flush left", function()
        local lines = rendered()
        ---@type string?
        local own
        for _, line in ipairs(lines) do
            if line:sub(1, 17) == "*nvim-config.txt*" then
                own = line
            end
        end
        eq(own, "*nvim-config.txt*  Configuration reference")
    end)

    -- `scripts/genhelp.lua` deletes and recreates `doc/`, so a sibling
    -- note file cannot survive to carry this warning and the rendered text
    -- is the only place it can live
    it("warns that the file is generated", function()
        -- Located relative to the file's own tag rather than by absolute
        -- index, so that adding a line to the header box does not fail
        -- this case over something it is not about
        local lines = rendered()
        ---@type integer
        local at = 0
        for i, line in ipairs(lines) do
            if line:sub(1, 17) == "*nvim-config.txt*" then
                at = i
            end
        end
        eq(
            lines[at + 2],
            "Generated by scripts/genhelp.lua; do not edit by hand."
        )
    end)

    it("omits the warning when no generator is named", function()
        local lines = vimdoc.render({
            file     = "x.txt",
            tagline  = "x",
            sections = { { title = "A", tag = "a" } },
        })
        eq(table.concat(lines, "\n"):find("do not edit", 1, true), nil)
    end)

    it("emits a contents block linking every section", function()
        local lines = table.concat(rendered(), "\n")
        eq(lines:find("*nvim-config-contents*", 1, true) ~= nil, true)
        eq(lines:find("|nvim-config-keymaps|", 1, true) ~= nil, true)
    end)

    it("never exceeds the help width and never trails whitespace", function()
        for _, line in ipairs(rendered()) do
            eq(vim.fn.strdisplaywidth(line) <= vimdoc.width, true)
            eq(line:match("[ \t]$"), nil)
        end
    end)

    -- Proves the output is a help file rather than merely text shaped like
    -- one: `helptags` has to find both tags, and `:help` has to resolve
    -- them, with the header box sitting above the file's own tag line
    it("produces tags helptags can index", function()
        local dir = vim.fn.tempname() .. "/doc"
        vim.fn.mkdir(dir, "p")
        vim.fn.writefile(rendered(), dir .. "/nvim-config.txt")
        vim.cmd.helptags(vim.fn.fnameescape(dir))

        local tags = vim.fn.readfile(dir .. "/tags")
        ---@type string[]
        local names = {}
        for _, tag in ipairs(tags) do
            table.insert(names, (tag:gsub("\t.*$", "")))
        end
        table.sort(names)

        eq(vim.tbl_contains(names, "nvim-config.txt"), true)
        eq(vim.tbl_contains(names, "nvim-config-keymaps"), true)
        eq(vim.tbl_contains(names, "nvim-config-contents"), true)

        vim.fn.delete(vim.fs.dirname(dir), "rf")
    end)
end)
