#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_coverage.lua
--
--

--
-- The registry: every module in this repository is either covered by a test
-- file named here, or exempt with a reason.
--
-- This is not a coverage measurement. It answers the one question a
-- line-coverage tool answers too late, ie. at review time rather than at
-- write time: was a module added and never tested at all? Nineteen of them
-- had no test file when this was written, and nothing said so.
--
-- It also guards the collection glob. `collect.find_files` matches
-- `tests/**/test_*.lua`, so a file named `tests/util_text_test.lua` would
-- sit in this directory looking like a test and never run, which is the
-- quietest way a suite can lose coverage.
--

local eq = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

--- Where each module's coverage lives, for the modules whose test file
--- cannot be derived from their path.
---
--- The derivation is "lua/util/git.lua" -> "tests/test_util_git.lua", ie.
--- the path under `lua/` with separators turned into underscores. Every
--- entry below is a place this repository deliberately departs from that:
--- an aggregate covered with its siblings, a submodule covered through the
--- dispatcher that loads it, or a wrapper covered through the command that
--- calls it.
---@type table<string, string>
local covered_by = {
    ["init.lua"] = "tests/test_init.lua",

    -- Aggregates and their siblings share one file each, since the values
    -- one applies are only meaningful next to the others
    ["lua/option/init.lua"]    = "tests/test_option.lua",
    ["lua/option/general.lua"] = "tests/test_option.lua",
    ["lua/option/view.lua"]    = "tests/test_option.lua",
    ["lua/option/fold.lua"]    = "tests/test_option.lua",
    ["lua/keymap/init.lua"]    = "tests/test_keymap.lua",
    ["lua/keymap/gx.lua"]      = "tests/test_keymap.lua",
    ["lua/usercmd/init.lua"]   = "tests/test_usercmd.lua",

    -- The specialised filetype modules are reached through
    -- `filetype.config`, which is what applies their declarations
    ["lua/filetype/claude.lua"]   = "tests/test_filetype_modules.lua",
    ["lua/filetype/dosini.lua"]   = "tests/test_filetype_modules.lua",
    ["lua/filetype/help.lua"]     = "tests/test_filetype_modules.lua",
    ["lua/filetype/kdl.lua"]      = "tests/test_filetype_modules.lua",
    ["lua/filetype/man.lua"]      = "tests/test_filetype_modules.lua",
    ["lua/filetype/markdown.lua"] = "tests/test_filetype_modules.lua",
    ["lua/filetype/prose.lua"]    = "tests/test_filetype_modules.lua",

    -- Command wrappers, covered through the command they back
    ["lua/usercmd/lua_checker.lua"]            = "tests/test_usercmd.lua",
    ["lua/usercmd/redirect_awkward_pager.lua"] = "tests/test_usercmd_redirect.lua",

    -- `lua/plugin.lua` is the enable/disable policy the spec sweep asserts
    ["lua/plugin.lua"] = "tests/test_spec.lua",
}

--- Modules with no test file, and the reason each is exempt.
---
--- A reason rather than a bare list, because "nothing tests this" is a
--- decision and the next person to read it deserves to know which decision
--- it was.
---@type table<string, string>
local exempt = {
    ["lua/util/spec.lua"]     = "superseded by lua/plugin.lua's import "
        .. "groups, and required by nothing; kept for reference only",
    ["lua/util/minitest.lua"] = "the suite's own configuration: every run "
        .. "is its test, and a test of it would be circular",
}

--- Every module this registry is answerable for: `init.lua` and everything
--- under `lua/`, bar the plugin specs.
---
--- `lua/spec/` is excluded deliberately. One file per plugin, asserted as a
--- directory by `tests/test_spec.lua`, is a different shape of coverage
--- from one test file per module, and 60-odd entries here would say
--- nothing. `lsp/` is excluded for the same reason.
---@return string[] paths
local modules = function()
    ---@type string[]
    local paths = { "init.lua" }

    -- Bound to a typed local first: `vim.fn.globpath` is declared as
    -- returning `any`, and iterating it directly leaves `path` untyped
    ---@type string[]
    local found = vim.fn.globpath("lua", "**/*.lua", true, true)
    for _, path in ipairs(found) do
        if not path:match("^lua/spec/") then
            table.insert(paths, path)
        end
    end
    table.sort(paths)
    return paths
end

--- The test file a module's path derives to.
---@param path string Repository-relative module path
---@return string test
local derived = function(path)
    local stem = path:gsub("^lua/", "")
        :gsub("%.lua$", "")
        :gsub("/", "_")
    return "tests/test_" .. stem .. ".lua"
end

describe("coverage", function()
    ---@type string[]
    local paths = modules()

    it("finds the modules", function()
        -- The generated cases below cannot fail over an empty list
        eq(#paths > 20, true)
    end)

    for _, path in ipairs(paths) do
        it(path .. " has a test file or a reason not to", function()
            local reason = exempt[path]
            if reason then
                -- An exemption has to say something: an empty string here
                -- would be the bare list this table exists to avoid
                eq({ path, #reason > 0 }, { path, true })
                return
            end

            local test = covered_by[path] or derived(path)
            eq(
                { path, test, vim.fn.filereadable(test) == 1 },
                { path, test, true }
            )
        end)
    end

    it("claims no coverage from a file that is gone", function()
        -- Both tables name files by hand, so an entry outlives the file it
        -- names. The check above would then pass on a derivation instead
        -- of reporting the stale entry.
        ---@type string[]
        local missing = {}
        for module, test in pairs(covered_by) do
            if vim.fn.filereadable(test) == 0 then
                table.insert(missing, module .. " -> " .. test)
            end
        end
        table.sort(missing)
        eq(missing, {})
    end)

    it("exempts nothing that no longer exists", function()
        ---@type string[]
        local gone = {}
        for path in pairs(exempt) do
            if vim.fn.filereadable(path) == 0 then
                table.insert(gone, path)
            end
        end
        table.sort(gone)
        eq(gone, {})
    end)

    it("collects every test file in this directory", function()
        -- `tests/helpers.lua` is the one file here that is deliberately not
        -- collected, and it is named rather than pattern-matched so that a
        -- second uncollected file has to be justified rather than just
        -- happen
        ---@type fun(): string[]
        local find_files = assert(
            require("util.minitest").opts.collect
                and require("util.minitest").opts.collect.find_files,
            "util.minitest no longer configures collect.find_files"
        )

        ---@type table<string, boolean>
        local collected = {}
        for _, path in ipairs(find_files()) do
            collected[path] = true
        end

        -- Bound to a typed local first, for the reason `modules` gives
        ---@type string[]
        local present = vim.fn.globpath("tests", "*.lua", true, true)

        ---@type string[]
        local ignored = {}
        for _, path in ipairs(present) do
            if not collected[path] then
                table.insert(ignored, path)
            end
        end

        table.sort(ignored)
        eq(ignored, { "tests/helpers.lua" })
    end)

    -- Deliberately not asserted here: that every test file is tracked by
    -- git. The hole is real (a test nobody committed passes locally forever
    -- and does not exist in CI) but the check fires against every file
    -- anyone is part way through writing, which makes a green suite
    -- impossible while drafting one. CI runs the committed tree, so it
    -- cannot be fooled by an uncommitted file either way.
end)
