#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/scripts/lazy_merge.lua
--
--

--
-- Runs lazy.nvim's real spec resolution over `lua/spec/` and prints what it
-- produced, as one line of JSON on stdout. `tests/test_lazy_integration.lua`
-- is what reads it; this exists as its own script so that the Neovim doing
-- the resolving is a separate process with its own `stdpath`, which is the
-- only way to point it at a throwaway profile.
--
-- Why a real lazy.nvim run is needed at all: `tests/test_spec.lua` checks
-- that every spec parses and names the plugin its filename claims, but it
-- never hands them to lazy.nvim. The `cond = false` / `enabled = false`
-- overrides `lua/plugin.lua` builds are *merged* by lazy.nvim across
-- imports, so whether they land on the right plugins is a property of that
-- merge and of nothing this repository can evaluate on its own.
--
-- Nothing here is allowed to reach the network or to change the profile it
-- runs in:
--
--   * `install.missing = false`, so a plugin that is not present stays
--     absent rather than being cloned.
--   * `checker`/`rocks` disabled, both of which fetch.
--   * lazy.nvim's own presence is asserted first, because `util.lazy.setup`
--     calls `M.install()` and would otherwise `git clone` it.
--
-- It still writes `state.json` and the lockfile into whatever profile it is
-- given, so give it a throwaway one. Run by hand as:
--
--     root=$(mktemp -d)
--     mkdir -p "$root/data/nvim/lazy"
--     ln -s "$(...)/lazy/lazy.nvim" "$root/data/nvim/lazy/lazy.nvim"
--     XDG_DATA_HOME="$root/data" XDG_STATE_HOME="$root/state" \
--         nvim --headless -u scripts/minimal_init.lua -l scripts/lazy_merge.lua
--

local joinpath = vim.fs.joinpath
local data_dir = vim.fn.stdpath("data")

local installed = joinpath(data_dir, "lazy", "lazy.nvim")
if vim.fn.isdirectory(installed) ~= 1 then
    -- Fail closed rather than let `util.lazy.setup` clone it: a script that
    -- silently reached the network would turn an absent plugin manager into
    -- a slow success instead of a failure
    error(
        "lazy.nvim is not installed at: " .. installed
            .. "\nthis script resolves specs against an existing lazy.nvim "
            .. "and never installs one"
    )
end

require("util.lazy").setup({
    spec = require("plugin").import(),

    -- The three overrides that keep this offline and read-only. HTTPS
    -- rather than the SSH `url_format` `lua/plugin.lua` uses, so that a
    -- machine with no key configured fails on the assertion rather than on
    -- an authentication prompt, in the event anything does try to fetch.
    install = { missing = false },
    checker = { enabled = false },
    rocks = { enabled = false },
    git = { url_format = "https://github.com/%s.git" },
})

--- The `lazy.core.config` fields this script reads.
---
--- Declared as a class rather than written as an inline `---@type` table
--- shape: `luafmt` re-indents a multi-line annotation differently on each
--- pass, which it reports as "formatting is not idempotent". lazy.nvim
--- ships LuaCATS for its public spec types but not for its internal
--- config, so without an annotation the repo-wide check reports this as
--- `no-unknown`.
---@class cgxx.lazy_merge.resolution
---@field plugins table<string, any>
---@field spec    cgxx.lazy_merge.resolved_spec

--- The subset of lazy.nvim's resolved spec state that distinguishes an
--- elided plugin from a condemned one.
---@class cgxx.lazy_merge.resolved_spec
---@field disabled         table<string, any>
---@field ignore_installed table<string, any>
---@field notifs           table<string, any>[]?

---@type cgxx.lazy_merge.resolution
local config = require("lazy.core.config")

--- Sorted keys of a set-shaped table.
---@param set table<string, any>
---@return string[] keys
local sorted = function(set)
    ---@type string[]
    local keys = vim.tbl_keys(set)
    table.sort(keys)
    return keys
end

--- Whatever lazy.nvim wanted to tell the user while resolving. Empty is the
--- only acceptable answer: a spec naming a plugin twice, or importing a
--- module that does not exist, arrives here rather than as an error.
---@type string[]
local reported = {}
---@type table<string, any>[]
local notifications = config.spec.notifs or {}
for _, notification in ipairs(notifications) do
    ---@type string
    local message = tostring(notification.msg)
    -- Bound to a local rather than inlined: `gsub` returns the count as a
    -- second value, which `table.insert` would read as its index argument
    ---@type string
    local collapsed = message:gsub("%s+", " ")
    table.insert(reported, collapsed)
end
table.sort(reported)

--- `ignore_installed` is the one place an elided plugin differs from a
--- condemned one after the merge: lazy.nvim puts `cond = false` plugins,
--- and their dependency closure, there so that `:Lazy clean` leaves them
--- installed, having also set `enabled = false` on them. That is why
--- `disabled` on its own cannot tell the two groups apart.
local payload = {
    plugins = sorted(config.plugins),
    disabled = sorted(config.spec.disabled),
    ignore_installed = sorted(config.spec.ignore_installed),
    reported = reported,
}

-- `io.write` rather than `print`, which is what this originally used and
-- which produced nothing at all: under `-l --headless`, `print` goes to
-- Neovim's message output and out on stderr, alongside lazy.nvim's own
-- "Plugin X is not installed" lines. `io.write` is the real stdout, which
-- is what the caller decodes. Not `io.stdout:write` either: selene's
-- `lua51` standard library does not carry `io.stdout`.
io.write(vim.json.encode(payload), "\n")
