#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_spec.lua
--
--

--
-- A plugin spec is only ever read by lazy.nvim, at startup, in a session
-- nothing here can stand in for. That leaves a whole directory whose
-- files are never executed by anything else: a typo in one is not a test
-- failure but a plugin that quietly stops loading, reported (if at all)
-- as a lazy.nvim error banner at the next start.
--
-- These cases go as far as that can be taken without lazy.nvim: every
-- file parses, evaluates, and produces the shape lazy.nvim will be handed.
-- `config`/`init`/`opts` functions are deliberately not called; they run
-- against a loaded plugin, which is not something this suite has.
--
-- The per-file assertions are generated as one case each rather than
-- written as a loop inside one case. A loop stops at its first failing
-- item, so a directory with two broken specs reported one of them per run,
-- and forty-odd files collapsed into a single dot in the reporter.
--

local eq = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

--- Loads path as a plain Lua chunk and returns what it evaluates to.
---
--- `loadfile` rather than `require`: these filenames carry dots (e.g.
--- `lua/spec/mini.test.lua`), so `require("spec.mini.test")` would look
--- for `lua/spec/mini/test.lua` and never find them.
---@param path string
---@return table<string | integer, any> value
local evaluated = function(path)
    local chunk = assert(loadfile(path), path .. " does not parse")
    ---@type table<string | integer, any>
    local value = chunk()
    return value
end

describe("spec", function()
    ---@type string[]
    local specs = vim.fn.globpath("lua/spec", "*.lua", true, true)

    it("finds the plugin specs", function()
        -- The generated cases below cannot fail over an empty list, since
        -- an empty list generates none of them, so the glob itself has to
        -- be asserted before they mean anything
        eq(#specs > 0, true)
    end)

    for _, path in ipairs(specs) do
        local file = vim.fn.fnamemodify(path, ":t")

        it("evaluates " .. file .. " to a table", function()
            ---@type boolean, any
            local ok, spec = pcall(evaluated, path)
            eq({ path, ok, type(spec) }, { path, true, "table" })
        end)

        it("names the plugin " .. file .. " claims", function()
            -- The repo convention: one file per plugin, named after the
            -- plugin's own repository. Matched loosely because the tails
            -- legitimately differ (`kdl.lua` -> `imsnif/kdl.vim`,
            -- `starry.lua` -> `ray-x/starry.nvim`) and because a few specs
            -- identify themselves with `url` rather than a short name.
            local spec = evaluated(path)
            local name = vim.fn.fnamemodify(path, ":t:r")
                :lower()

            ---@type string
            local id = ""
            for _, key in ipairs({ 1, "url", "dir", "name" }) do
                local value = spec[key]
                if type(value) == "string" then
                    -- Bound to a typed local rather than cast inline:
                    -- `luafmt` moves an inline `--[[@as T]]` onto a line
                    -- of its own, detaching it from what it annotates
                    ---@type string
                    local text = value
                    id         = id .. " " .. text:lower()
                end
            end

            eq({ path, id:find(name, 1, true) ~= nil }, { path, true })
        end)
    end
end)

describe("plugin.import", function()
    ---@type table<string, any>
    local loaded = package.loaded

    ---@type table<string, string?>
    local environ = vim.env

    --- `lua/plugin.lua` as loaded with termux set or unset.
    ---
    --- A fresh require is the only way to ask: the Termux additions to
    --- `M.condemn` are made once, when the module is first loaded.
    ---@param termux string? Value for TERMUX_VERSION, nil to unset
    ---@return { import: fun(): table<string | integer, any>[] } plugin
    local reloaded = function(termux)
        local saved            = environ.TERMUX_VERSION
        environ.TERMUX_VERSION = termux

        loaded["plugin"] = nil
        local plugin     = require("plugin")

        environ.TERMUX_VERSION = saved
        loaded["plugin"]       = nil
        return plugin
    end

    --- The override specs the named group of `M.import()` expands to.
    ---
    --- Expanded here rather than returning the group itself: the list
    --- `M.import()` answers with holds both the plain
    --- `{ import = "spec" }` entry and the two named groups, so its
    --- element type is the looser of the two and `entry.import` comes
    --- back untyped.
    ---@param name   "elide" | "condemn"
    ---@param termux string?             Value for TERMUX_VERSION, nil to unset
    ---@return table<string | integer, any>[] specs
    local overrides = function(name, termux)
        for _, entry in ipairs(reloaded(termux).import()) do
            if entry.name == name then
                ---@type fun(): table<string | integer, any>[]
                local expand = entry.import
                return expand()
            end
        end
        error("no import group named " .. name)
    end

    local plugin = require("plugin")

    it("imports the spec directory first", function()
        -- Ordering is not load order (lazy.nvim merges these overrides
        -- into each plugin's real spec either way), but the directory is
        -- what the two override groups are overriding
        eq(plugin.import()[1], { import = "spec" })
    end)

    it("elides with cond and condemns with enabled", function()
        -- The distinction is deliberate: `cond = false` leaves a plugin
        -- installed but never loaded, `enabled = false` takes it out
        -- altogether. Calling each group's `import` is what checks it
        -- produces specs lazy.nvim will accept rather than bare strings.
        for name, field in pairs({ elide = "cond", condemn = "enabled" }) do
            local specs = overrides(name, nil)
            eq({ name, #specs > 0 }, { name, true })

            for _, spec in ipairs(specs) do
                eq({ name, type(spec[1]) }, { name, "string" })
                eq({ name, spec[1], spec[field] }, { name, spec[1], false })
            end
        end
    end)

    it("names a plugin this config actually has a spec for", function()
        -- The regression test for a slug that went stale in the move of
        -- these lists out of `lua/util/spec.lua`: the Termux entry for
        -- mason-lspconfig carried its *filename*
        -- ("mason-org/mason-lspconfig.nvim.lua"), matched no spec, and so
        -- silently stopped disabling anything on the one platform the
        -- entry exists for.
        ---@type table<string, boolean>
        local known = {}

        --- Records slug under its "owner/repo" tail, so that a spec
        --- declaring itself by `url` (`lua/spec/mkdnflow.lua`) counts as
        --- the same plugin an override names by slug.
        ---@param slug any Ignored unless it is a string
        ---@return nil
        local record = function(slug)
            if type(slug) ~= "string" then
                return
            end
            ---@type string
            local text = slug
            local tail = text:gsub("%.git$", "")
                :match("([^/]+/[^/]+)$")
            if tail then
                known[tail] = true
            end
        end

        ---@type string[]
        local paths = vim.fn.globpath("lua/spec", "*.lua", true, true)
        for _, path in ipairs(paths) do
            local spec = evaluated(path)
            record(spec[1])
            record(spec.url)

            -- Dependencies count too: a plugin this config never writes
            -- a file for still exists, as another spec's dependency,
            -- and an override may legitimately target one
            ---@type any[]?
            local dependencies = spec.dependencies
            for _, dependency in ipairs(dependencies or {}) do
                record(dependency)
                if type(dependency) == "table" then
                    record(dependency[1])
                end
            end
        end

        -- Both environments, since the entries that go stale most
        -- quietly are the ones only one platform ever builds
        for _, termux in ipairs({ "", "0.118.0" }) do
            local under = termux == "" and "ordinary" or "termux"
            for _, name in ipairs({ "elide", "condemn" }) do
                local specs = overrides(name, termux ~= "" and termux or nil)
                for _, spec in ipairs(specs) do
                    ---@type string
                    local slug = spec[1]
                    eq(
                        { under, name, slug, known[slug] or false },
                        { under, name, slug, true }
                    )
                end
            end
        end
    end)
end)

describe("lsp", function()
    ---@type string[]
    local configs = vim.fn.globpath("lsp", "*.lua", true, true)

    --- The only modules a server configuration may fail to find here.
    ---
    --- Named rather than accepted in the general case: "module '...' not
    --- found" is also what a *typo* in a `require` produces, so a pattern
    --- matching any missing module would pass a configuration that can
    --- never work in a session either. These two exist only once lazy.nvim
    --- has installed the plugin, which this suite deliberately has not.
    ---@type table<string, boolean>
    local installable = {
        ["schemastore"] = true,
    }

    it("finds the server configurations", function()
        eq(#configs > 0, true)
    end)

    it("configures exactly the servers mason installs", function()
        -- Two lists that have to agree and nothing made them: a server in
        -- `ensure_installed` with no `lsp/<name>.lua` is installed and
        -- never configured, and a configuration with no entry there is
        -- enabled only where the binary happens to exist already, since
        -- `automatic_enable` enables what mason-lspconfig knows about. The
        -- same class of bug as the stale `condemn` slug above, and just as
        -- quiet.
        local spec = evaluated("lua/spec/mason-lspconfig.nvim.lua")

        ---@type table<string, any>
        local opts = spec.opts

        ---@type string[]
        local installed = opts.ensure_installed

        ---@type string[]
        local declared = {}
        for _, path in ipairs(configs) do
            table.insert(declared, vim.fn.fnamemodify(path, ":t:r"))
        end

        table.sort(installed)
        table.sort(declared)
        eq(installed, declared)
    end)

    for _, path in ipairs(configs) do
        local file = vim.fn.fnamemodify(path, ":t")

        it("evaluates " .. file .. " to a table", function()
            ---@type boolean, any
            local ok, config = pcall(evaluated, path)

            if ok then
                eq({ path, type(config) }, { path, "table" })
                return
            end

            -- Bound first: `luafmt` splits a `tostring(x):match()`
            -- chain across lines, which Lua then reads as a call
            -- followed by a new statement
            local err     = tostring(config)
            local missing = err:match("module '([^']+)' not found")

            -- The module it could not find is asserted by name, so the
            -- failure message says which one rather than just "something
            -- was missing"
            eq(
                { path, missing, installable[missing or ""] or false },
                { path, missing, true }
            )
        end)
    end
end)
