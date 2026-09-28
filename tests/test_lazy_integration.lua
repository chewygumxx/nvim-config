#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_lazy_integration.lua
--
--

--
-- The one file here that hands this configuration's specs to the real
-- lazy.nvim. `tests/test_spec.lua` goes as far as a spec can be checked
-- without it, ie. that every file parses, evaluates to a table and names
-- the plugin its filename claims. What it cannot check is the *merge*:
-- `lua/plugin.lua` disables plugins by importing bare
-- `{ slug, cond = false }` / `{ slug, enabled = false }` fragments that
-- lazy.nvim combines with each plugin's real spec, and whether those land
-- on the right plugins is a property of lazy.nvim's resolution rather than
-- of any file in this repository.
--
-- The interesting result, and the reason this is worth the second process:
-- after the merge, elided and condemned plugins are *indistinguishable* in
-- `Config.spec.disabled`. lazy.nvim's `fix_cond` sets `enabled = false` on
-- anything with `cond = false`, so both groups land there and both leave
-- `Config.plugins` entirely. The distinction survives only in
-- `Config.spec.ignore_installed`, which holds the elided plugins and their
-- dependency closure so that `:Lazy clean` does not remove them, and which
-- condemned plugins never enter. That is the assertion below, and it is
-- also why `tests/test_lockfile.lua` does not try to tell the two apart
-- from the lockfile: lazy.nvim retains entries for both.
--
-- What this does and does not catch, established by mutation rather than
-- assumed, because the difference is not obvious:
--
--   * Caught: the import wiring coming apart. Dropping
--     `M.factory("elide")` from `M.import()` fails two cases, which is the
--     regression nothing else here notices, since `lua/plugin.lua` would
--     still list the same slugs and `tests/test_spec.lua` would still
--     find them all valid.
--
--   * Caught: lazy.nvim changing what `ignore_installed` means. That is an
--     upstream canary, and the nightly leg is where it would first show.
--
--   * Not caught: a slug moved between `elide` and `condemn`. The cases
--     below read those two lists from the same module that drove the
--     resolution, so a move changes the expectation and the behaviour
--     together and is invisible here. Which group a plugin belongs in is a
--     policy decision, and this file checks the mechanism.
--
--   * Not caught: two specs naming one plugin, which lazy.nvim merges as
--     fragments by design, or a spec naming a repository that does not
--     exist, which is indistinguishable from an uninstalled one when
--     nothing is allowed to fetch.
--
-- Run in a throwaway profile, in a separate process, because `stdpath` is
-- fixed at startup and the resolution writes `state.json` and the lockfile
-- into whichever profile it finds. lazy.nvim and mini.test are symlinked in
-- from the real profile rather than cloned, so this reaches the network
-- never and takes about a second.
--
-- Requires lazy.nvim to be installed, and fails if it is not. That is
-- deliberate, and matches `scripts/minimal_init.lua` already requiring
-- mini.test: a configuration managed by lazy.nvim always has it, and the
-- alternative is a case that silently checks nothing on the machines where
-- it matters most.
--

---@type mini.test
local MiniTest = require("mini.test")
local eq       = MiniTest.expect.equality

local joinpath = vim.fs.joinpath

--- lazy.nvim's plugin name for a slug: its tail, minus any `.git`. This is
--- the key lazy.nvim stores a plugin under in every table read below.
---@param slug string
---@return string name
local named = function(slug)
    ---@type string
    local trimmed = slug:gsub("%.git$", "")
    return trimmed:match("[^/]+$") or trimmed
end

--- Turns a list into a set, for the membership tests below.
---@param list string[]
---@return table<string, true> set
local set_of = function(list)
    ---@type table<string, true>
    local set = {}
    for _, item in ipairs(list) do
        set[item] = true
    end
    return set
end

--- Resolves the spec directory through a real lazy.nvim, in a throwaway
--- profile that is deleted before this returns.
---
--- Run once for the whole group rather than per case: it is the expensive
--- part, every case reads the same answer, and doing it here means the
--- profile's lifetime is the subprocess's rather than the group's, so no
--- teardown hook has to remember to remove it.
---@return { plugins: string[], disabled: string[], ignore_installed: string[], reported: string[] }? merged
---@return string failure
local resolve = function()
    local source = joinpath(vim.fn.stdpath("data"), "lazy")
    if vim.fn.isdirectory(joinpath(source, "lazy.nvim")) ~= 1 then
        return nil,
            "lazy.nvim is not installed at " .. joinpath(source, "lazy.nvim")
    end

    local profile = vim.fn.tempname()
    local data    = joinpath(profile, "data")
    vim.fn.mkdir(joinpath(data, "nvim", "lazy"), "p")
    vim.fn.mkdir(joinpath(profile, "state"), "p")

    -- Symlinked rather than copied: lazy.nvim alone is tens of megabytes,
    -- and nothing in this run writes into either plugin
    for _, plugin in ipairs({ "lazy.nvim", "mini.test" }) do
        vim.uv.fs_symlink(
            joinpath(source, plugin),
            joinpath(data, "nvim", "lazy", plugin)
        )
    end

    ---@type string[]
    local command = {
        vim.v.progpath,
        "--headless",
        "-u",
        "scripts/minimal_init.lua",
        "-l",
        "scripts/lazy_merge.lua",
    }

    -- Added to this process's environment rather than replacing it, which
    -- `vim.system` does by default: the child still needs `PATH` and `HOME`
    ---@type vim.SystemOpts
    local opts = {
        text = true,
        env = {
            XDG_DATA_HOME = data,
            XDG_STATE_HOME = joinpath(profile, "state"),
            XDG_CACHE_HOME = joinpath(profile, "cache"),
        },
    }

    local result = vim.system(command, opts):wait(60000)

    vim.fn.delete(profile, "rf")

    ---@type string
    local out = result.stdout or ""
    ---@type boolean, any
    local ok, decoded = pcall(vim.json.decode, out)
    if not ok or type(decoded) ~= "table" then
        ---@type string
        local stderr = tostring(result.stderr)
        return nil, "scripts/lazy_merge.lua produced no JSON (exit "
                .. tostring(result.code)
                .. "): "
                .. stderr:gsub("%s+", " "):sub(1, 400)
    end
    return decoded, ""
end

describe("lazy.nvim spec merge", function()
    local resolved, failure = resolve()

    ---@type { plugins: string[], disabled: string[], ignore_installed: string[], reported: string[] }
    local merged = resolved
        or {
            plugins = {},
            disabled = {},
            ignore_installed = {},
            reported = {},
        }

    it("resolves the spec directory", function()
        eq(failure, "")
        -- Every case below compares against these lists, so an empty
        -- resolution has to fail here rather than pass everywhere
        eq(#merged.plugins > 0, true)
    end)

    it("reports nothing while resolving", function()
        -- A duplicate plugin, or an `import` naming a module that is not
        -- there, arrives as a notification rather than an error
        eq(merged.reported, {})
    end)

    it("disables every plugin it elides or condemns", function()
        local plugin   = require("plugin")
        local disabled = set_of(merged.disabled)

        ---@type string[]
        local enabled = {}
        for _, group in ipairs({ plugin.elide, plugin.condemn }) do
            ---@type string[]
            local slugs = group
            for _, slug in ipairs(slugs) do
                if not disabled[named(slug)] then
                    table.insert(enabled, slug)
                end
            end
        end
        table.sort(enabled)
        eq(enabled, {})
    end)

    it("keeps elided plugins installed", function()
        -- `cond = false` means installed but never loaded, which lazy.nvim
        -- records by putting the plugin in `ignore_installed` so that
        -- `:Lazy clean` leaves it alone
        local ignored = set_of(merged.ignore_installed)

        ---@type string[]
        local cleanable = {}
        ---@type string[]
        local elide = require("plugin").elide
        for _, slug in ipairs(elide) do
            if not ignored[named(slug)] then
                table.insert(cleanable, slug)
            end
        end
        table.sort(cleanable)
        eq(cleanable, {})
    end)

    it("takes condemned plugins out altogether", function()
        -- `enabled = false` means not installed, so a condemned plugin must
        -- *not* be protected from `:Lazy clean`. This is the only place the
        -- two groups differ after the merge, which is the whole reason this
        -- file spawns a second Neovim.
        local ignored = set_of(merged.ignore_installed)

        ---@type string[]
        local spared = {}
        ---@type string[]
        local condemn = require("plugin").condemn
        for _, slug in ipairs(condemn) do
            if ignored[named(slug)] then
                table.insert(spared, slug)
            end
        end
        table.sort(spared)
        eq(spared, {})
    end)

    it("disables nothing it does not name", function()
        local plugin = require("plugin")

        ---@type table<string, true>
        local intended = {}
        for _, group in ipairs({ plugin.elide, plugin.condemn }) do
            ---@type string[]
            local slugs = group
            for _, slug in ipairs(slugs) do
                intended[named(slug)] = true
            end
        end

        -- A spec may carry its own condition where that condition is about
        -- the plugin rather than a policy about it, and two currently do:
        -- `lazydev.nvim` keys off a `.luarc.json` being present and
        -- `mkdnflow` is off for a crash explained in its spec. Both are
        -- also listed in `lua/plugin.lua`, so neither shows up here, and
        -- anything that does is a plugin disabled somewhere unread.
        ---@type string[]
        local unexplained = {}
        for _, name in ipairs(merged.disabled) do
            if not intended[name] then
                table.insert(unexplained, name)
            end
        end
        table.sort(unexplained)
        eq(unexplained, {})
    end)

    it("resolves every spec it does not disable", function()
        local plugin = require("plugin")

        ---@type table<string, true>
        local off = {}
        for _, group in ipairs({ plugin.elide, plugin.condemn }) do
            ---@type string[]
            local slugs = group
            for _, slug in ipairs(slugs) do
                off[named(slug)] = true
            end
        end

        local present = set_of(merged.plugins)

        ---@type string[]
        local specs = vim.fn.globpath("lua/spec", "*.lua", true, true)

        ---@type string[]
        local absent = {}
        for _, path in ipairs(specs) do
            local chunk = assert(loadfile(path), path .. " does not parse")
            ---@type table<string | integer, any>
            local spec = chunk()
            ---@type string?
            local slug
            for _, key in ipairs({ 1, "url", "name" }) do
                if type(spec[key]) == "string" then
                    ---@type string
                    local text = spec[key]
                    slug       = text
                    break
                end
            end

            if slug ~= nil then
                local name = named(slug)
                if not off[name] and not present[name] then
                    table.insert(
                        absent,
                        name .. " (" .. vim.fn.fnamemodify(path, ":t") .. ")"
                    )
                end
            end
        end
        table.sort(absent)
        eq(absent, {})
    end)

    it("strands no plugin on a disabled dependency", function()
        -- Read from the spec files rather than from the resolution:
        -- lazy.nvim deletes a disabled plugin's fragments and rebuilds its
        -- dependents without it, so the resolved `dependencies` never
        -- shows the gap. The dependent still loads, and its own `require`
        -- of the missing plugin is the first thing to fail, which is how
        -- `telescope-undo.nvim` outlived an elided `telescope.nvim`.
        local enabled  = set_of(merged.plugins)
        local disabled = set_of(merged.disabled)

        ---@type string[]
        local specs = vim.fn.globpath("lua/spec", "*.lua", true, true)

        ---@type string[]
        local stranded = {}
        for _, path in ipairs(specs) do
            local chunk = assert(loadfile(path), path .. " does not parse")
            ---@type table<string | integer, any>
            local spec = chunk()
            ---@type (string | table)[]
            local dependencies = spec.dependencies or {}

            local slug = spec[1]
            if type(slug) == "string" and enabled[named(slug)] then
                for _, dependency in ipairs(dependencies) do
                    ---@type any
                    local dep = type(dependency) == "table" and dependency[1]
                        or dependency
                    if type(dep) == "string" and disabled[named(dep)] then
                        table.insert(
                            stranded,
                            named(slug) .. " -> " .. named(dep)
                        )
                    end
                end
            end
        end
        table.sort(stranded)
        eq(stranded, {})
    end)
end)
