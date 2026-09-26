#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_init.lua
--
--

--
-- `init.lua`'s load order is the most documented invariant in this
-- repository and was the only one with no test, because it cannot have one
-- in this process: the suite's own Neovim has already required half of
-- these modules, and sourcing the real `init.lua` here would bootstrap
-- lazy.nvim into the session running the tests.
--
-- So this is the one file that works through `MiniTest.new_child_neovim()`.
-- The child is started on `scripts/minimal_init.lua`, exactly as a headless
-- run is, which gives it this checkout's runtimepath and none of the
-- machine's own configuration. Whatever it sets, maps, or defines dies with
-- it, so unlike `test_option`/`test_keymap`/`test_highlight` there is
-- nothing here to capture and restore.
--
-- `plugin` is stubbed in the child before `init.lua` is sourced. That call
-- is `util.lazy`'s bootstrap: it would `git clone` lazy.nvim and then every
-- plugin spec, ie. the network, on a CI runner, for a fact about ordering
-- that the stub reports just as well.
--

local MiniTest = require("mini.test")     --[[@as mini.test]]
local eq       = MiniTest.expect.equality

--- The order `init.lua` documents, in the terms its comments use: option
--- and keymap first, `filetype` after both so its `FileType` overrides
--- win, `autocmd`/`usercmd` after filetype registration, `plugin` after
--- keymap/filetype/autocmd since specs key off `vim.g.mapleader`, filetype
--- triggers and augroups, and `highlight` last so it overwrites whatever
--- the colorscheme and treesitter plugins set.
---@type string[]
local order = {
    "option",
    "keymap",
    "filetype",
    "autocmd",
    "usercmd",
    "plugin",
    "highlight",
}

--- Sourced in the child: records which `setup()` ran in what order, then
--- sources the real `init.lua`.
---
--- Recording the calls rather than the requires is what makes this an
--- assertion about `init.lua` and not about its dependency graph: any of
--- these modules may be pulled in early as somebody else's dependency, but
--- only `init.lua` calls their `setup`.
local instrument = [[
    _G.cgxx_calls = {}

    ---@type table<string, boolean>
    local watched = vim.iter(%s):fold({}, function(acc, name)
        acc[name] = true
        return acc
    end)

    -- Stubbed before anything can require it for real: `plugin.setup()`
    -- clones lazy.nvim and every spec
    package.loaded["plugin"] = {
        setup = function() end,
    }

    local real = require
    _G.require = function(name)
        local mod = real(name)
        if
            watched[name]
            and type(mod) == "table"
            and type(mod.setup) == "function"
            and not mod.cgxx_watched
        then
            local inner    = mod.setup
            mod.setup      = function(...)
                table.insert(_G.cgxx_calls, name)
                return inner(...)
            end
            mod.cgxx_watched = true
        end
        return mod
    end

    local ok, err  = pcall(dofile, "init.lua")
    _G.require     = real
    _G.cgxx_loaded = ok
    _G.cgxx_error  = ok and "" or tostring(err)
]]

describe("init", function()
    local child = MiniTest.new_child_neovim()

    before_each(function()
        -- Started the way CI starts the suite itself, so the child
        -- resolves `require("option")` against this checkout rather than
        -- against `stdpath("config")`
        child.restart({ "-u", "scripts/minimal_init.lua" })
        child.lua(instrument:format(vim.inspect(order)))
    end)

    after_each(function()
        child.stop()
    end)

    it("sources without error", function()
        -- Asserted before the ordering cases, since a raised error leaves
        -- the call list truncated and every one of them would then fail
        -- while describing the symptom rather than the cause
        eq(child.lua_get("_G.cgxx_error"), "")
        eq(child.lua_get("_G.cgxx_loaded"), true)
    end)

    it("calls every module's setup in the documented order", function()
        eq(child.lua_get("_G.cgxx_calls"), order)
    end)

    it("sets the leader before the plugin specs are read", function()
        -- Not just "before `plugin` in the list": the specs read
        -- `vim.g.mapleader` at require time, so what matters is that it
        -- holds the intended value by then, and `keymap` sets it on
        -- require rather than in its `setup`
        eq(child.lua_get("vim.g.mapleader"), "\\")
    end)

    it("applies the options a session would have", function()
        -- The end to end check the in-process option cases cannot make:
        -- these are the values a real startup leaves behind, arrived at
        -- through `init.lua` rather than by calling one module directly
        eq(child.lua_get("vim.o.shiftwidth"), 4)
        eq(child.lua_get("vim.o.expandtab"), true)
        eq(child.lua_get("vim.o.foldmethod"), "expr")
        eq(child.lua_get("vim.o.statusline") ~= "", true)
    end)

    it("leaves the highlight groups it defines last in place", function()
        -- The reason `highlight.setup()` is last: nothing after it can
        -- overwrite `Normal`, and its transparent background survives
        eq(
            child.lua_get("vim.api.nvim_get_hl(0, { name = 'Normal' }).fg"),
            0xcad6ff
        )
        eq(
            child.lua_get("vim.api.nvim_get_hl(0, { name = 'Normal' }).bg"),
            vim.NIL
        )
    end)

    it("registers the user commands and augroups a session has", function()
        -- `usercmd` and `autocmd` are reached through `init.lua` here, so
        -- this fails if either is dropped from it, which the per-module
        -- files cannot notice
        eq(
            child.lua_get("vim.fn.exists(':XXInsertHeader')"),
            2
        )
        eq(
            child.lua_get(
                "#vim.api.nvim_get_autocmds({ group = 'cgxx.file_entry' }) > 0"
            ),
            true
        )
    end)
end)
