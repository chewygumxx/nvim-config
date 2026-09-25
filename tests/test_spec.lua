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
        -- Both loops below are vacuously true over an empty list, so the
        -- glob itself has to be asserted before they mean anything
        eq(#specs > 0, true)
    end)

    it("evaluates every spec to a table", function()
        for _, path in ipairs(specs) do
            ---@type boolean, any
            local ok, spec = pcall(evaluated, path)
            eq({ path, ok, type(spec) }, { path, true, "table" })
        end
    end)

    it("names the plugin its filename claims", function()
        -- The repo convention: one file per plugin, named after the
        -- plugin's own repository. Matched loosely because the tails
        -- legitimately differ (`kdl.lua` -> `imsnif/kdl.vim`,
        -- `starry.lua` -> `ray-x/starry.nvim`) and because a few specs
        -- identify themselves with `url` rather than a short name.
        for _, path in ipairs(specs) do
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
        end
    end)
end)

describe("util.spec", function()
    it("imports the spec directory", function()
        eq(require("util.spec")[1], { import = "spec" })
    end)

    it("elides each plugin it names with cond = false", function()
        -- The elision list is a function so that lazy.nvim expands it at
        -- import time; calling it here is what checks it produces specs
        -- lazy.nvim will accept rather than, say, a list of strings.
        ---@type { name: string, import: fun(): table[] }
        local elision = require("util.spec")[2]
        eq(elision.name, "elision")

        local specs = elision.import()
        eq(#specs > 0, true)
        for _, spec in ipairs(specs) do
            eq({ spec[1], spec.cond }, { spec[1], false })
            eq(type(spec[1]), "string")
        end
    end)
end)

describe("lsp", function()
    ---@type string[]
    local configs = vim.fn.globpath("lsp", "*.lua", true, true)

    it("finds the server configurations", function()
        eq(#configs > 0, true)
    end)

    it("evaluates every server configuration to a table", function()
        for _, path in ipairs(configs) do
            ---@type boolean, any
            local ok, config = pcall(evaluated, path)

            -- A couple of these pull settings out of a plugin
            -- (`schemastore`), which only exists once lazy.nvim has
            -- installed it. That one failure is expected here; anything
            -- else, ie. a syntax error or a bad API call, is not.
            if ok then
                eq({ path, type(config) }, { path, "table" })
            else
                -- Bound first: `luafmt` splits a `tostring(x):match()`
                -- chain across lines, which Lua then reads as a call
                -- followed by a new statement
                local err     = tostring(config)
                local missing = err:match("module '[^']+' not found")
                eq({ path, missing ~= nil }, { path, true })
            end
        end
    end)
end)
