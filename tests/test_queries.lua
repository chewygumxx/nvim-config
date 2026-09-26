#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_queries.lua
--
--

--
-- `queries/` is the other directory nothing here executes. A Tree-sitter
-- query is read by Neovim only when a buffer of that language is opened,
-- and a broken one does not raise where it was written: it surfaces as a
-- buffer with no highlighting, or as an error banner naming a line number
-- in a file the user was not editing.
--
-- Validation happens at three depths, because the parsers these queries
-- are written against are not all available:
--
--   1. Structure. Every file is parsed as the *query language*, using the
--      `query` grammar Neovim bundles to highlight `.scm` files. That needs
--      none of the target grammars, so all eight files are covered, and it
--      catches the faults that actually get written: an unbalanced paren, a
--      stray line, a malformed predicate call.
--
--   2. Resolvability. Every `#predicate?` and `#directive!` a file uses has
--      to be one Neovim knows after `util.treesitter.setup()` has run. Three
--      of the six predicates in use here are this repository's own, so
--      "known to Neovim" is not the test; "known once we have registered
--      ours" is. This is the parity gate between `queries/comment` and
--      `lua/util/treesitter.lua`, in both directions.
--
--   3. Compilation. `vim.treesitter.query.parse` checks a query against the
--      grammar itself, ie. that the node names exist and the captures are
--      well formed. It needs the parser, so it reaches only the languages
--      Neovim ships a parser for. Which ones those are is registered below
--      rather than discovered, so a parser arriving or leaving is a test
--      failure to read and not a silent change in how much was checked.
--
-- Structure alone does not catch everything: a predicate called with the
-- wrong number of arguments parses cleanly and only fails at depth 3, so
-- the six files with no bundled parser are genuinely less well covered
-- than the two with one. That is a limit of the environment, and the
-- registry is what keeps it visible.
--

local eq = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

--- Every query file in the repository.
---
--- `bundled` is whether Neovim ships a parser for the language the file's
--- directory names, which decides whether depth 3 applies. `extends` is
--- whether the file carries an `; extends` comment: without one a query in
--- `queries/` *replaces* the runtime query for that language rather than
--- adding to it, which is a decision worth stating per file instead of
--- inferring from whichever behaviour happens to be current.
---@type table<string, { bundled: boolean, extends: boolean }>
local expected = {
    -- This repository's own: highlights the file headers described in
    -- CLAUDE.md's Conventions, and the source of all three custom
    -- predicates.
    ["queries/comment/highlights.scm"] = { bundled = false, extends = false },

    ["queries/markdown/highlights.scm"] = { bundled = true, extends = false },
    ["queries/markdown_inline/highlights.scm"] = {
        bundled = true,
        extends = false,
    },

    -- norg and norg_meta are read only when neorg loads, and
    -- `lua/plugin.lua` condemns it, so these are dormant until that
    -- changes. Dormant is not the same as unchecked: depths 1 and 2 still
    -- apply, and they are the depths a hand edit breaks.
    ["queries/norg/folds.scm"] = { bundled = false, extends = false },
    ["queries/norg/highlights.scm"] = { bundled = false, extends = false },
    ["queries/norg/injections.scm"] = { bundled = false, extends = false },
    ["queries/norg_meta/highlights.scm"] = { bundled = false, extends = false },
    ["queries/norg_meta/indents.scm"] = { bundled = false, extends = false },
}

--- The query predicates this configuration registers itself, mapped to why
--- each exists. Neovim does not provide these, so a query using one is
--- valid only once `util.treesitter.setup()` has run.
---@type table<string, string>
local provided = {
    ["adjacent?"] = "matches captures that sit on one line with only "
        .. "whitespace between them",
    ["last-matching?"] = "matches only the last capture satisfying a "
        .. "pattern",
    ["header-line?"] = "matches captures on a repo-slug or path header line",
}

--- Query kinds Neovim itself resolves from the runtimepath. A file named
--- anything else is never read, however well formed it is.
---@type string[]
local kinds = { "highlights", "injections", "locals", "folds", "indents" }

--- Returns every `ERROR` or missing node in text parsed as a query, as
--- `"<type> at <row>:<col>"` strings.
---
--- Parsed through the `query` grammar rather than the grammar the file
--- targets, which is what makes this work for a language whose parser is
--- absent.
---@param text string
---@return string[] faults
local malformed = function(text)
    local parser = vim.treesitter.get_string_parser(text, "query")
    local tree   = parser:parse(true)[1]

    ---@type string[]
    local faults = {}

    ---@param node TSNode
    local function walk(node)
        if node:type() == "ERROR" or node:missing() then
            local row, column = node:start()
            table.insert(
                faults,
                string.format("%s at %d:%d", node:type(), row + 1, column + 1)
            )
        end
        for child in node:iter_children() do
            walk(child)
        end
    end

    walk(tree:root())
    return faults
end

--- Returns the predicate and directive names text calls, each with its
--- trailing `?` or `!` so a predicate cannot be confused with a directive
--- of the same name.
---@param text string
---@return table<string, true> called
local called = function(text)
    local parser = vim.treesitter.get_string_parser(text, "query")
    local tree   = parser:parse(true)[1]

    ---@type table<string, true>
    local names = {}

    ---@param node TSNode
    local function walk(node)
        if node:type() == "predicate" then
            ---@type string?, string?
            local name, kind
            for child in node:iter_children() do
                local kid = child:type()
                -- The name is the first identifier; a predicate's
                -- arguments are identifiers too
                if kid == "identifier" and not name then
                    name = vim.treesitter.get_node_text(child, text)
                elseif kid == "predicate_type" then
                    kind = vim.treesitter.get_node_text(child, text)
                end
            end
            if name then
                names[name .. (kind or "")] = true
            end
        end
        for child in node:iter_children() do
            walk(child)
        end
    end

    walk(tree:root())
    return names
end

--- Reads path into one string.
---@param path string
---@return string text
local contents = function(path)
    ---@type string[]
    local lines = vim.fn.readfile(path)
    return table.concat(lines, "\n")
end

describe("queries", function()
    ---@type string[]
    local found = vim.fn.globpath("queries", "*/*.scm", true, true)

    --- What Neovim knows before this configuration registers anything,
    --- which is the only way to tell a core predicate from one of ours.
    --- Both lists come back carrying their own `?`/`!` marker.
    ---@type table<string, true>
    local core = {}
    for _, name in ipairs(vim.treesitter.query.list_predicates()) do
        core[name] = true
    end
    for _, name in ipairs(vim.treesitter.query.list_directives()) do
        core[name] = true
    end

    -- Registering a predicate is process-global and there is no API to
    -- undo it, so this is not captured and restored the way the option and
    -- keymap suites do. It is safe to leak: no other file in the suite
    -- parses a query, and `add_predicate` is called with `force = true`,
    -- so a later `util.treesitter.setup()` is a no-op rather than a clash.
    --
    -- It does mean the snapshot above has to be taken first, and that the
    -- snapshot is only meaningful if no earlier file in the suite already
    -- called this. That is asserted rather than assumed below.
    require("util.treesitter").setup()

    it("finds the query files", function()
        -- The generated cases below cannot fail over an empty list, since
        -- an empty list generates none of them, so the glob itself has to
        -- be asserted before they mean anything
        eq(#found > 0, true)
    end)

    it("registers every query file it ships", function()
        ---@type string[]
        local unregistered = {}
        for _, path in ipairs(found) do
            if expected[path] == nil then
                table.insert(unregistered, path)
            end
        end
        table.sort(unregistered)
        eq(unregistered, {})
    end)

    it("registers nothing that no longer exists", function()
        ---@type table<string, true>
        local present = {}
        for _, path in ipairs(found) do
            present[path] = true
        end

        ---@type string[]
        local stale = {}
        for path in pairs(expected) do
            if not present[path] then
                table.insert(stale, path)
            end
        end
        table.sort(stale)
        eq(stale, {})
    end)

    it("provides every custom predicate its queries call", function()
        -- The snapshot is worth nothing if it was taken after something
        -- else had already registered ours, so say so rather than passing
        -- an assertion that has quietly stopped distinguishing anything
        ---@type string[]
        local preregistered = {}
        for name in pairs(provided) do
            if core[name] then
                table.insert(preregistered, name)
            end
        end
        table.sort(preregistered)
        eq(preregistered, {})

        ---@type table<string, true>
        local used = {}
        for _, path in ipairs(found) do
            for name in pairs(called(contents(path))) do
                used[name] = true
            end
        end

        -- Anything Neovim already knew is not ours to provide, so the
        -- comparison is against what is left over after core
        ---@type string[]
        local ours = {}
        for name in pairs(used) do
            if not core[name] then
                table.insert(ours, name)
            end
        end
        table.sort(ours)

        ---@type string[]
        local declared = vim.tbl_keys(provided)
        table.sort(declared)

        eq(ours, declared)
    end)

    it("uses every custom predicate it provides", function()
        ---@type table<string, true>
        local used = {}
        for _, path in ipairs(found) do
            for name in pairs(called(contents(path))) do
                used[name] = true
            end
        end

        ---@type string[]
        local unused = {}
        for name, reason in pairs(provided) do
            -- A registration has to say something, for the reason
            -- test_coverage.lua's exemptions do
            if #reason == 0 then
                table.insert(unused, name .. " has an empty reason")
            elseif not used[name] then
                table.insert(unused, name)
            end
        end
        table.sort(unused)
        eq(unused, {})
    end)

    it("checks every language whose parser is bundled", function()
        ---@type string[]
        local mismatched = {}
        for path, want in pairs(expected) do
            local lang      = vim.fn.fnamemodify(path, ":h:t")
            local available = pcall(vim.treesitter.language.inspect, lang)
            if available ~= want.bundled then
                table.insert(
                    mismatched,
                    string.format(
                        "%s: registered bundled=%s, actually %s",
                        path,
                        tostring(want.bundled),
                        tostring(available)
                    )
                )
            end
        end
        table.sort(mismatched)
        eq(mismatched, {})
    end)

    for _, path in ipairs(found) do
        local file = path:gsub("^queries/", "")
        local lang = vim.fn.fnamemodify(path, ":h:t")

        it("parses " .. file .. " as a query", function()
            eq({ path, malformed(contents(path)) }, { path, {} })
        end)

        it("resolves every predicate " .. file .. " calls", function()
            -- Both lists already carry their own `?`/`!` marker
            ---@type table<string, true>
            local known = {}
            for _, name in ipairs(vim.treesitter.query.list_predicates()) do
                known[name] = true
            end
            for _, name in ipairs(vim.treesitter.query.list_directives()) do
                known[name] = true
            end

            ---@type string[]
            local unresolved = {}
            for name in pairs(called(contents(path))) do
                if not known[name] then
                    table.insert(unresolved, name)
                end
            end
            table.sort(unresolved)
            eq({ path, unresolved }, { path, {} })
        end)

        it("names a query kind Neovim reads for " .. file, function()
            local kind = vim.fn.fnamemodify(path, ":t:r")
            eq({ path, vim.list_contains(kinds, kind) }, { path, true })
        end)

        it("declares whether " .. file .. " extends the runtime", function()
            -- Neovim accepts `; extends` with any number of leading
            -- semicolons and surrounding space
            local carries = contents(path):match("\n?%s*;+%s*extends%s*\n")
                ~= nil
            eq({ path, carries }, { path, expected[path].extends })
        end)

        if expected[path] ~= nil and expected[path].bundled then
            it("compiles " .. file .. " against " .. lang, function()
                local ok, err = pcall(
                    vim.treesitter.query.parse,
                    lang,
                    contents(path)
                )
                eq({ path, ok, ok and "" or tostring(err) }, { path, true, "" })
            end)
        end
    end
end)
