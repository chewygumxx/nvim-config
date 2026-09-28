#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_lockfile.lua
--
--

--
-- `lazy-lock.json` is written by lazy.nvim and read by `:Lazy restore`, so
-- nothing in the normal course of events checks it against the specs it is
-- supposed to pin. A stale lock is not an error anywhere: a spec with no
-- entry installs whatever the default branch points at today, and an entry
-- whose spec has been deleted simply sits there.
--
-- The matching is exact rather than fuzzy, which is worth knowing because
-- it looks like it should not be. A lock key is lazy.nvim's *plugin name*,
-- and lazy.nvim derives that from the tail of the slug: `numToStr/Comment.nvim`
-- becomes `Comment.nvim`. Comparing lock keys against spec *filenames*
-- would need the loose substring matching `test_spec.lua` uses for its own
-- purposes (`kdl.lua` -> `imsnif/kdl.vim`), and would report a dozen false
-- mismatches. Comparing against the slug tail is a bijection.
--
-- Three things this deliberately does not assert. Whether a locked commit
-- is the one a spec's `tag`/`branch`/`commit` would resolve to: that needs
-- the network, and the lock is the record of what was installed rather than
-- a restatement of the spec. Whether an entry is reachable: a commit can be
-- garbage collected upstream and only a fetch would know. And whether the
-- lock distinguishes an elided plugin from a condemned one: it does not, by
-- design, since lazy.nvim retains the entries of both so that re-enabling
-- either returns to a known commit.
--

---@type mini.test
local MiniTest = require("mini.test")
local eq       = MiniTest.expect.equality

--- The lockfile, relative to the repository root the suite runs from.
local LOCKFILE = "lazy-lock.json"

--- Lock entries that correspond to no spec and no declared dependency,
--- mapped to why each is expected anyway.
---@type table<string, string>
local unspecced = {
    ["lazy.nvim"] = "lazy.nvim manages itself; `util.lazy.M.defaults` "
        .. "clones it rather than `lua/spec/` declaring it",
}

--- Specs with no lock entry yet, mapped to why.
---
--- Adding a plugin spec and running `:Lazy sync` are two steps, and the
--- second needs the network, so a spec can legitimately exist before its
--- pin does. Naming it here is how that stays a deliberate, visible gap
--- rather than the lock quietly falling behind the directory.
---@type table<string, string>
local unpinned = {}

--- Loads path as a plain Lua chunk and returns what it evaluates to.
---
--- `loadfile` rather than `require`, for the reason `test_spec.lua` gives:
--- these filenames carry dots, so `require("spec.mini.test")` would look
--- for `lua/spec/mini/test.lua`.
---@param path string
---@return table<string | integer, any> value
local evaluated = function(path)
    local chunk = assert(loadfile(path), path .. " does not parse")
    ---@type table<string | integer, any>
    local value = chunk()
    return value
end

--- The plugin name lazy.nvim derives from a slug or URL, ie. its tail with
--- any `.git` removed. This is the key a lock entry is stored under.
---@param slug string
---@return string name
local named = function(slug)
    ---@type string
    local trimmed = slug:gsub("%.git$", "")
    return trimmed:match("[^/]+$") or trimmed
end

--- The slug a spec identifies its plugin by, or nil if it names none.
---@param spec table<string | integer, any>
---@return string? slug
local slug_of = function(spec)
    for _, key in ipairs({ 1, "url", "name" }) do
        local value = spec[key]
        if type(value) == "string" then
            ---@type string
            local text = value
            return text
        end
    end
    return nil
end

describe("lazy-lock.json", function()
    ---@type table<string, { branch: string, commit: string }>
    local lock = {}

    ---@type table<string, string>
    local declared = {}

    ---@type table<string, true>
    local dependency = {}

    ---@type string[]
    local specs = vim.fn.globpath("lua/spec", "*.lua", true, true)

    if vim.fn.filereadable(LOCKFILE) == 1 then
        ---@type string[]
        local lines = vim.fn.readfile(LOCKFILE)
        ---@type boolean, any
        local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
        if ok and type(decoded) == "table" then
            lock = decoded
        end
    end

    for _, path in ipairs(specs) do
        local spec = evaluated(path)
        local slug = slug_of(spec)
        if slug ~= nil then
            declared[named(slug)] = vim.fn.fnamemodify(path, ":t")
        end

        -- A dependency is installed and locked without a spec file of its
        -- own, so it accounts for a lock entry the same way a spec does
        ---@type any[]
        local dependencies = spec.dependencies or {}
        for _, entry in ipairs(dependencies) do
            if type(entry) == "string" then
                dependency[named(entry)] = true
            elseif type(entry) == "table" and type(entry[1]) == "string" then
                ---@type string
                local text              = entry[1]
                dependency[named(text)] = true
            end
        end
    end

    it("is present and parses", function()
        eq(vim.fn.filereadable(LOCKFILE), 1)
        -- Asserted before the comparisons below, which would all pass
        -- vacuously against an empty table
        eq(vim.tbl_count(lock) > 0, true)
    end)

    it("finds the plugin specs to compare against", function()
        eq(#specs > 0, true)
    end)

    it("records a branch and a commit for every entry", function()
        ---@type string[]
        local malformed = {}
        for name, entry in pairs(lock) do
            ---@type string[]
            local keys = vim.tbl_keys(entry)
            table.sort(keys)

            -- A full lowercase hex sha1. Lua patterns carry no repetition
            -- count, so the length is checked alongside the pattern rather
            -- than written into it.
            local commit = entry.commit
            local sha    = type(commit) == "string" and #commit == 40
                and commit:match("^[0-9a-f]+$") ~= nil

            if not vim.deep_equal(keys, { "branch", "commit" }) then
                table.insert(
                    malformed,
                    name .. ": keys are " .. table.concat(keys, ",")
                )
            elseif not sha then
                table.insert(
                    malformed,
                    name .. ": commit is " .. tostring(commit)
                )
            end
        end
        table.sort(malformed)
        eq(malformed, {})
    end)

    it("pins every plugin a spec declares", function()
        ---@type string[]
        local missing = {}
        for name, file in pairs(declared) do
            if lock[name] == nil and unpinned[name] == nil then
                table.insert(missing, name .. " (" .. file .. ")")
            end
        end
        table.sort(missing)
        eq(missing, {})
    end)

    it("pins nothing no spec or dependency accounts for", function()
        ---@type string[]
        local orphaned = {}
        for name in pairs(lock) do
            local accounted = declared[name] ~= nil or dependency[name]
                or unspecced[name] ~= nil
            if not accounted then
                table.insert(orphaned, name)
            end
        end
        table.sort(orphaned)
        eq(orphaned, {})
    end)

    it("states a reason for every entry it excuses", function()
        ---@type string[]
        local unreasoned = {}
        for _, registry in ipairs({ unspecced, unpinned }) do
            for name, reason in pairs(registry) do
                if #reason == 0 then
                    table.insert(unreasoned, name)
                end
            end
        end
        table.sort(unreasoned)
        eq(unreasoned, {})
    end)

    it("excuses nothing that no longer needs excusing", function()
        ---@type string[]
        local stale = {}
        for name in pairs(unspecced) do
            if lock[name] == nil then
                table.insert(stale, "unspecced: " .. name)
            end
        end
        for name in pairs(unpinned) do
            if lock[name] ~= nil or declared[name] == nil then
                table.insert(stale, "unpinned: " .. name)
            end
        end
        table.sort(stale)
        eq(stale, {})
    end)
end)
