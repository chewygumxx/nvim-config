#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_lazy.lua
--
--

--
-- `util.lazy` runs once, at startup, before anything else this config
-- does, and a mistake in it is not a failing feature but a session with
-- no plugins at all. Nothing here reaches the network: the clone cases
-- clone a local fixture repository, and `M.setup` is pointed at a stand-in
-- `lazy` module on the runtimepath so that the real one, which would go on
-- to install every spec in the config, is never called.
--

local lazy = require("util.lazy")
local eq   = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

--- `package.loaded` and `vim.env`, bound to typed locals.
---
--- Both are declared loosely enough that indexing them directly leaves
--- LuaLS unable to infer a type, which this repo's `no-unknown` setting
--- reports as a warning; an annotated local is the way to say what they
--- hold without an inline cast `luafmt` would detach.
---@type table<string, any>
local loaded = package.loaded

---@type table<string, string?>
local environ = vim.env

--- Runs git in dir, raising if it fails.
---@param dir string Repository to run in
---@param ... string git arguments
---@return nil
local git = function(dir, ...)
    local args = { ... }
    local cmd  = { "git", "-C", dir }
    vim.list_extend(cmd, args)

    local result = vim.system(cmd, { text = true }):wait()
    if result.code ~= 0 then
        error(
            string.format(
                "fixture `git %s` failed (%d): %s",
                table.concat(args, " "),
                result.code,
                result.stderr or ""
            )
        )
    end
end

--- Swallows every `vim.notify`, returning the messages it collected and
--- the original, for the caller to restore.
---@return string[] notified
---@return fun(msg: string, level?: integer, opts?: table) original
local quieten = function()
    ---@type string[]
    local notified = {}
    local original = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(msg)
        notified[#notified + 1] = msg
    end
    return notified, original
end

describe("util.lazy.defaults", function()
    it("imports plugin specs from lua/spec", function()
        -- The whole spec directory is reached through this one value
        eq(lazy.defaults.spec, "spec")
    end)

    it("prefers a local checkout of the author's own plugins", function()
        eq(lazy.defaults.dev.patterns, { "chewygumxx" })
        eq(lazy.defaults.dev.fallback, true)
    end)

    it("installs plugins under the data directory", function()
        local data = vim.fn.stdpath("data") .. ""
        eq(lazy.defaults.root, data .. "/lazy")
        eq(lazy.defaults.path, data .. "/lazy/lazy.nvim")
    end)

    --- The environment variables the update checker is decided by.
    ---@type string[]
    local flags = { "HERDR_ENV", "TERMUX_VERSION" }

    --- Re-requires `util.lazy` with exactly env applied, and returns
    --- whether its update checker came out enabled.
    ---
    --- A fresh require is the only way to ask: the flag is computed once,
    --- when the module is first loaded. Both variables are set from env
    --- rather than added to the ambient environment, because a machine
    --- that already exports one (this config's author's does export
    --- `HERDR_ENV`) would otherwise decide the answer for every case.
    ---@param env table<string, string?> Value per variable, nil to unset
    ---@return boolean enabled
    local checker_with = function(env)
        ---@type table<string, string?>
        local saved = {}
        for _, name in ipairs(flags) do
            saved[name]   = environ[name]
            environ[name] = env[name]
        end

        loaded["util.lazy"] = nil
        ---@type { defaults: { checker: { enabled: boolean } } }
        local reloaded = require("util.lazy")
        local enabled  = reloaded.defaults.checker.enabled

        for _, name in ipairs(flags) do
            environ[name] = saved[name]
        end
        loaded["util.lazy"] = nil
        require("util.lazy")
        return enabled
    end

    it("enables the update checker on an ordinary machine", function()
        eq(checker_with({}), true)
    end)

    it("disables the update checker under Herdr", function()
        eq(checker_with({ HERDR_ENV = "1" }), false)
    end)

    it("disables the update checker under Termux", function()
        -- Termux has no business fetching from every plugin repository on
        -- a timer, and `mason` is disabled there for the same reason
        eq(checker_with({ TERMUX_VERSION = "0.118.0" }), false)
    end)
end)

describe("util.lazy.install", function()
    ---@type string, string
    local source, root

    ---@type fun(msg: string, level?: integer, opts?: table)
    local notify

    ---@type string[]
    local notified

    before_each(function()
        root = vim.fn.tempname()
        vim.fn.mkdir(root, "p")
        source = root .. "/source"
        vim.fn.mkdir(source, "p")

        -- A local path is a perfectly good clone URL, which is what keeps
        -- this case off the network
        git(source, "init", "--quiet", "--initial-branch=cloneme")
        git(source, "config", "user.email", "test@example.invalid")
        git(source, "config", "user.name", "Test")
        vim.fn.writefile({ "return {}" }, source .. "/init.lua")
        git(source, "add", "-A")
        git(
            source,
            "-c",
            "commit.gpgsign=false",
            "commit",
            "--quiet",
            "-m",
            "i"
        )

        notified, notify = quieten()
    end)

    after_each(function()
        vim.notify = notify
        vim.fn.delete(root, "rf")
    end)

    it("clones the requested branch and reports success", function()
        local dest = root .. "/clone"
        eq(lazy.install(source, dest, "cloneme"), 0)
        eq(vim.fn.isdirectory(dest .. "/.git"), 1)
        eq(vim.fn.filereadable(dest .. "/init.lua"), 1)
    end)

    it("reports a failed clone rather than raising", function()
        -- A startup that cannot install lazy.nvim has to say so and carry
        -- on, since erroring out of `init.lua` leaves no usable session
        local dest = root .. "/missing"
        eq(lazy.install(source .. "-nope", dest, "cloneme") ~= 0, true)
        eq(vim.fn.isdirectory(dest), 0)

        eq(notified[2], "Failed to clone lazy.nvim")
    end)
end)

describe("util.lazy.setup", function()
    ---@type string
    local root

    ---@type table<string, any>?
    local passed

    ---@type integer
    local clones

    ---@type fun(url: string, path: string, branch: string): number
    local real_install

    before_each(function()
        -- A stand-in `lazy` module, laid out so that `M.setup`'s own
        -- `vim.opt.rtp:append(opts.path)` is what puts it on the
        -- runtimepath, exactly as the real clone would be
        root      = vim.fn.tempname()
        local dir = root .. "/lazy.nvim/lua/lazy"
        vim.fn.mkdir(dir, "p")
        -- It records what it was given on itself rather than in a global,
        -- which `selene` forbids and which would outlive the case
        vim.fn.writefile({
            "local M = {}",
            "M.seen = nil",
            "M.setup = function(opts) M.seen = opts end",
            "return M",
        }, dir .. "/init.lua")

        passed = nil
        clones = 0

        real_install = lazy.install
        ---@diagnostic disable-next-line: duplicate-set-field
        lazy.install = function()
            clones = clones + 1
            return 0
        end
    end)

    after_each(function()
        lazy.install   = real_install
        loaded["lazy"] = nil
        vim.opt.rtp:remove(root .. "/lazy.nvim")
        vim.fn.delete(root, "rf")
    end)

    --- Runs `M.setup` against the stand-in and returns the options it
    --- handed to `require("lazy").setup()`.
    ---@param opts table<string, any> Caller options, minus `path`
    ---@return table<string, any> applied
    local applied = function(opts)
        opts.path = root .. "/lazy.nvim"
        lazy.setup(opts)

        ---@type { seen: table<string, any>? }
        local stand_in = require("lazy")
        return assert(
            stand_in.seen,
            "require('lazy').setup() was never called"
        )
    end

    it("derives the clone URL from the caller's url_format", function()
        -- What `lua/plugin.lua` overrides, and the only reason it has to
        -- touch this module at all
        passed = applied({ git = { url_format = "git@github.com:%s.git" } })
        eq(passed.url, "git@github.com:chewygumxx/lazy.nvim.git")
    end)

    it("defaults the clone URL to HTTPS", function()
        passed = applied({})
        eq(passed.url, "https://github.com/chewygumxx/lazy.nvim.git")
    end)

    it("merges caller options into the defaults rather than over", function()
        -- A shallow merge would drop every other `git` key, taking the
        -- log arguments, timeout and throttle with it
        passed = applied({ git = { url_format = "git@github.com:%s.git" } })
        eq(passed.git.timeout, lazy.defaults.git.timeout)
        eq(passed.git.log, lazy.defaults.git.log)
        eq(passed.spec, "spec")
    end)

    it("skips the clone when lazy.nvim is already installed", function()
        applied({})
        eq(clones, 0)
    end)

    it("clones when the install path is missing", function()
        -- Stubbed to fail, which also covers the other half of that
        -- branch: a clone that did not work has to abort setup rather
        -- than go on to `require("lazy")` and error out of `init.lua`
        ---@diagnostic disable-next-line: duplicate-set-field
        lazy.install = function()
            clones = clones + 1
            return 128
        end

        lazy.setup({ path = root .. "/absent" })
        eq(clones, 1)
        eq(loaded["lazy"], nil)
    end)
end)
