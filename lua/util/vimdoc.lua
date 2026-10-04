#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/vimdoc.lua
--
--

--
-- Renders a structured description of this configuration into Vim help
-- syntax, ie. the `doc/*.txt` that `:help` reads.
--
-- Pure, and deliberately so: nothing here inspects the running session,
-- reads a buffer or touches the filesystem. `scripts/genhelp.lua` does the
-- harvesting and the writing, and hands the result here as plain data.
-- That split is what lets `tests/test_util_vimdoc.lua` assert the column
-- arithmetic below without running any module's `setup()`.
--
-- The layout rules are Vim's rather than this repository's, which is why
-- `M.width` is 78 and not `.editorconfig`'s 80: a help window is 78
-- columns of text, and `runtime/doc/*.txt` is written to that. Tags are
-- `*name*` flush right against that same column, and `|name|` is a link to
-- one. `helptags` finds a tag anywhere in the file, so the header box this
-- renders above the file's own tag line costs nothing.
--

local M = {}

local util_header = require("util.header")
local util_text   = require("util.text")

--- Column a help file's text wraps at. Vim's own, not this repository's.
---@type integer
M.width = 78

--- Column an entry's description starts at, and the hanging indent its
--- continuation lines take. Wide enough for `<leader>` plus two keys and
--- for the longest `XX`-prefixed command name.
---@type integer
M.indent = 24

--- Comment syntax the header box is rendered in. Help files have no
--- comment syntax at all, so one is assumed rather than derived, the way
--- `util.header.frontmatter` assumes an HTML comment for Markdown.
---@type string
local commentstring = "# %s"

--- Modeline clauses that precede `filetype=help`, supplied verbatim.
---
--- `noexpandtab` is deliberately absent, though `runtime/doc` carries it:
--- everything this module emits is space-indented, so setting it would
--- describe the file wrongly.
---@type string
local modeline_prepend = " textwidth=78 tabstop=8"

--- Display width of s, counted in screen cells rather than bytes so that
--- the box-drawing and arrow characters a slug line may carry do not push
--- a flush-right tag out of true.
---@param s string
---@return integer cells
local width_of = function(s)
    return vim.fn.strdisplaywidth(s)
end

--- Returns the longest prefix of s that fits in cells columns, and what is
--- left of it. At least one character is always taken, so a caller looping
--- on the remainder cannot spin.
---@param s     string
---@param cells integer
---@return string prefix
---@return string rest
local split_at = function(s, cells)
    local taken = 0
    for i = 1, vim.fn.strchars(s), 1 do
        if width_of(vim.fn.strcharpart(s, 0, i)) > cells then
            break
        end
        taken = i
    end
    taken = math.max(taken, 1)
    return vim.fn.strcharpart(s, 0, taken), vim.fn.strcharpart(s, taken)
end

--- Breaks any line wider than `M.width` at the width, continuing the
--- remainder at indent.
---
--- `util.text.wrap_comment` breaks on whitespace alone, which is right for
--- prose and wrong here: an option value like 'statusline' or a slash-run
--- like a command's argument list is one token and would be emitted whole,
--- past the column a help window shows. Truncating instead would make the
--- page state the value wrongly, so the token is broken and kept.
---@param lines  string[]
---@param indent string   Prefix each continuation line carries
---@return string[] lines
M.fit = function(lines, indent)
    ---@type string[]
    local out = {}
    for _, line in ipairs(lines) do
        local rest  = line
        local first = true
        -- The indent has to be counted with the remainder rather than
        -- against it: a tail of 75 cells fits on its own and does not fit
        -- beneath a 24-cell gutter, and testing the tail alone emitted it
        -- at 99
        while true do
            local prefix = first and "" or indent
            if width_of(prefix) + width_of(rest) <= M.width then
                out[#out + 1] = prefix .. rest
                break
            end
            local chunk, tail = split_at(rest, M.width - width_of(prefix))
            out[#out + 1]     = prefix .. chunk
            rest              = tail
            first             = false
        end
    end
    return out
end

--- Returns left with tag placed flush right against `M.width`, separated
--- by at least one space.
---@param left string
---@param tag  string Bare tag name, rendered as `*tag*`
---@return string line
M.flush_right = function(left, tag)
    local marked = "*" .. tag .. "*"
    local pad    = M.width - width_of(left) - width_of(marked)
    return left .. string.rep(" ", math.max(pad, 1)) .. marked
end

--- Returns a full-width rule of char, the delimiter above a heading.
---@param char string Single character, conventionally "=" or "-"
---@return string rule
M.rule = function(char)
    return string.rep(char, M.width)
end

---@class cgxx.vimdoc.Entry
---@field lhs   string Left column, eg. `<leader>ac` or `:XXWip`
---@field desc? string Right column; the entry is bare without one
---@field tag?  string Bare tag name, emitted flush right above the entry

--- Renders one entry as its tag line, if any, then its two columns.
---
--- The description hangs at `M.indent`, and the left column joins the
--- first description line when it fits in that gutter. A tag takes a line
--- of its own above rather than sharing the first: sharing would push a
--- long `lhs` and its tag past `M.width` with no good way to recover.
---@param entry cgxx.vimdoc.Entry
---@return string[] lines
M.entry = function(entry)
    ---@type string[]
    local lines = {}

    if entry.tag then
        lines[#lines + 1] = M.flush_right("", entry.tag)
    end

    local desc = entry.desc or ""
    if desc == "" then
        lines[#lines + 1] = entry.lhs
        return lines
    end

    local gutter  = string.rep(" ", M.indent)
    local wrapped = util_text.wrap_comment(desc, M.width, {
        commentstring = gutter .. "%s",
    })

    -- Splice `lhs` over the first line's gutter rather than emitting it
    -- separately, so a short mapping and its description share one line
    if width_of(entry.lhs) + 1 <= M.indent then
        local pad  = string.rep(" ", M.indent - width_of(entry.lhs))
        wrapped[1] = entry.lhs .. pad .. wrapped[1]:sub(M.indent + 1)
    else
        table.insert(wrapped, 1, entry.lhs)
    end

    vim.list_extend(lines, M.fit(wrapped, gutter))
    return lines
end

---@class cgxx.vimdoc.Section
---@field title    string              Heading text, emitted as given
---@field tag      string              Bare tag name for the heading
---@field intro?   string              Prose paragraph beneath the heading
---@field entries? cgxx.vimdoc.Entry[] Two-column body

--- Renders one section: its rule, its tagged heading, its intro prose and
--- its entries.
---@param section cgxx.vimdoc.Section
---@return string[] lines
M.section = function(section)
    ---@type string[]
    local lines = { M.rule("="), M.flush_right(section.title, section.tag), "" }

    if section.intro and section.intro ~= "" then
        local intro = util_text.wrap_comment(section.intro, M.width, {
            commentstring = "%s",
        })
        vim.list_extend(lines, M.fit(intro, ""))
        lines[#lines + 1] = ""
    end

    for _, entry in ipairs(section.entries or {}) do
        vim.list_extend(lines, M.entry(entry))
    end

    lines[#lines + 1] = ""
    return lines
end

--- Renders the table of contents: one dotted line per section, linking to
--- its tag.
---
--- Numbered rather than bulleted because `:help` readers navigate a
--- contents block by `CTRL-]` on the link, and the number is what makes a
--- section referable in prose elsewhere.
---@param sections cgxx.vimdoc.Section[]
---@return string[] lines
M.contents = function(sections)
    ---@type string[]
    local lines = {}
    for i, section in ipairs(sections) do
        local left        = string.format("    %d. %s ", i, section.title)
        local link        = "|" .. section.tag .. "|"
        local dots        = M.width - width_of(left) - width_of(link)
        lines[#lines + 1] = left .. string.rep(".", math.max(dots, 1)) .. link
    end
    return lines
end

---@class cgxx.vimdoc.Opt
---@field file       string                Help file name, eg. `nvim-config.txt`
---@field tagline    string                Text beside the file's own tag
---@field slug?      string                Repository, boxed as `~slug.git`
---@field path?      string                Repo-relative path, boxed after `::: `
---@field spdx?      string                SPDX identifier for the header
---@field generator? string                Script named in the do-not-edit line
---@field sections   cgxx.vimdoc.Section[]

--- Renders a whole help file, header box included.
---
--- No closing modeline is emitted, though `runtime/doc/*.txt` carries one:
--- the header's own modeline sits inside the first five lines, which is
--- where Vim reads one from, so a second would be a second statement of
--- the same thing.
---@param opt cgxx.vimdoc.Opt
---@return string[] lines
M.render = function(opt)
    local lines = util_header.plain({
        commentstring = commentstring,
        slug          = opt.slug,
        path          = opt.path,
        spdx          = opt.spdx,
        modeline      = {
            et      = false,
            sw      = false,
            ft      = "help",
            prepend = modeline_prepend,
        },
    })

    -- The file's own tag goes flush left with its description beside it,
    -- which is the one place a help file does not align a tag right
    vim.list_extend(lines, {
        "*" .. opt.file .. "*  " .. opt.tagline,
        "",
    })

    -- The only durable place to say this. A help file is read inside the
    -- editor, where correcting a line in place is the natural reflex, and
    -- `scripts/genhelp.lua` deletes and recreates the whole directory, so
    -- a sibling note file could not survive to carry the warning. The
    -- generator names itself rather than being named here, since it is the
    -- thing that knows what it is called
    if opt.generator then
        vim.list_extend(lines, {
            "Generated by " .. opt.generator .. "; do not edit by hand.",
            "",
        })
    end

    -- Hoisted rather than inlined: `gsub` returns a count as its second
    -- value, and this stem is concatenated rather than passed on, so the
    -- count would surface as a stray number were the call ever moved
    local stem    = opt.file:gsub("%.txt$", "")
    local toc_tag = stem .. "-contents"
    vim.list_extend(lines, {
        M.rule("="),
        M.flush_right("CONTENTS", toc_tag),
        "",
    })
    vim.list_extend(lines, M.contents(opt.sections))
    lines[#lines + 1] = ""

    for _, section in ipairs(opt.sections) do
        vim.list_extend(lines, M.section(section))
    end

    for i = 1, #lines, 1 do
        lines[i] = lines[i]:gsub("[ \t]+$", "")
    end

    return lines
end

return M
