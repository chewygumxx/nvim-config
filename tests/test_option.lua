#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_option.lua
--
--

--
-- These apply the real global options `init.lua` applies at startup, so
-- unlike every other file here they mutate the session rather than a
-- fixture. What they must not do is leave it mutated: the whole suite
-- shares one Neovim process and files run in alphabetical order, so
-- anything left set here is inherited by every `test_util_*` file after
-- it. `tests/test_util_statusline.lua` in particular reads `vim.o
-- .statusline` as its "original", which is only meaningful if this file
-- has put it back.
--
-- The expected values double as the restore list, so an option added to
-- an assertion is an option that gets restored, with no second list to
-- keep in step. Which makes the completeness of those lists load-bearing
-- rather than tidy: an option a module writes and no list mentions is one
-- nothing restores. "writes no option it does not document" is what holds
-- them to it, by watching the writes themselves rather than trusting the
-- list to have named them all.
--

local eq = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

--- Every global option value `option.general` documents.
---@type table<string, string | boolean | integer>
local general = {
    clipboard     = "unnamedplus",
    undofile      = true,
    mouse         = "",
    expandtab     = true,
    shiftwidth    = 4,
    tabstop       = 4,
    linebreak     = true,
    virtualedit   = "block",
    formatoptions = "tcqjro",
    ignorecase    = true,
    smartcase     = true,
    spelllang     = "en",
}

--- Every global option value `option.view` documents, bar 'statusline',
--- which is derived rather than declared and is asserted separately.
---@type table<string, string | boolean | integer>
local view = {
    termguicolors  = true,
    number         = true,
    relativenumber = true,
    scrolloff      = 5,
    splitright     = true,
    jumpoptions    = "view",
}

--- Every global option value `option.fold` applies.
---@type table<string, string | boolean | integer>
local fold = {
    foldmethod = "expr",
    foldlevel  = 2,
    fillchars  = "fold: ",
    foldtext   = "v:lua.require(\"option.fold\").foldtext()",
}

--- 'statusline', which `option.view` writes by way of
--- `util.statusline.setup()` rather than declaring in its own table.
---@type table<string, string | boolean | integer>
local derived = {
    statusline = "",
}

--- Reads name's global value.
---@param name string
---@return string | boolean | integer value
local get = function(name)
    return vim.api.nvim_get_option_value(name, {})
end

--- Captures the current value of every option in want, plus 'statusline'.
---@param ... table<string, string | boolean | integer> Option tables
---@return table<string, string | boolean | integer> saved
local capture = function(...)
    ---@type table<string, string | boolean | integer>
    local saved = { statusline = get("statusline") }
    for _, want in ipairs({ ... }) do
        for name in pairs(want) do
            saved[name] = get(name)
        end
    end
    return saved
end

--- Restores what `capture` saved.
---@param saved table<string, string | boolean | integer>
---@return nil
local restore = function(saved)
    for name, value in pairs(saved) do
        vim.api.nvim_set_option_value(name, value, {})
    end
end

--- Asserts that every option in want holds its expected value.
---
--- Every mismatch is collected and asserted once, rather than compared
--- option by option: `eq` raises, so the first wrong option used to be the
--- only one a run could report, and a change that moved several of them
--- took as many runs to understand.
---@param want table<string, string | boolean | integer>
---@return nil
local applied = function(want)
    ---@type string[]
    local wrong = {}
    for name, value in pairs(want) do
        local got = get(name)
        if got ~= value then
            table.insert(
                wrong,
                string.format(
                    "%s is %s, want %s",
                    name,
                    vim.inspect(got),
                    vim.inspect(value)
                )
            )
        end
    end

    table.sort(wrong)
    eq(wrong, {})
end

--- The sorted names of every option in the given tables.
---@param ... table<string, string | boolean | integer> Option tables
---@return string[] names
local names = function(...)
    ---@type string[]
    local out = {}
    for _, want in ipairs({ ... }) do
        for name in pairs(want) do
            table.insert(out, name)
        end
    end
    table.sort(out)
    return out
end

--- Every option name setup writes, in the order it writes them.
---
--- Observed at the call rather than by diffing values afterwards, for two
--- reasons: an option written with the value it already holds is invisible
--- to a diff, and `option.fold` writes through `vim.opt`/`vim.o` rather
--- than the API, which both end up here anyway.
---
--- Nothing is applied while the stub is installed, so this cannot itself
--- leave behind the undocumented option it exists to find.
---@param setup fun(): nil
---@return string[] names Sorted, one per write
local written = function(setup)
    local real = vim.api.nvim_set_option_value
    ---@type string[]
    local seen = {}

    -- Three parameters, matching the real arity: a narrower stub would
    -- retype the field for the whole workspace
    ---@param name   string
    ---@param _value string | boolean | integer | nil
    ---@param _opts  vim.api.keyset.option?
    ---@return nil
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.api.nvim_set_option_value = function(name, _value, _opts)
        table.insert(seen, name)
    end

    -- Restored before the assert, so a raising `setup` cannot leave the
    -- API stubbed for every case after this one
    local ok, err                 = pcall(setup)
    vim.api.nvim_set_option_value = real
    assert(ok, err)

    table.sort(seen)
    return seen
end

describe("option.general.setup", function()
    ---@type table<string, string | boolean | integer>
    local saved

    before_each(function()
        saved = capture(general)
    end)
    after_each(function()
        restore(saved)
    end)

    it("applies its documented global option values", function()
        require("option.general").setup()
        applied(general)
    end)

    it("writes no option it does not document", function()
        eq(written(require("option.general").setup), names(general))
    end)
end)

describe("option.view.setup", function()
    ---@type table<string, string | boolean | integer>
    local saved

    before_each(function()
        saved = capture(view)
    end)
    after_each(function()
        restore(saved)
    end)

    it("applies its documented global option values", function()
        require("option.view").setup()
        applied(view)
    end)

    it("installs the git-aware statusline", function()
        require("option.view").setup()
        eq(vim.o.statusline, require("util.statusline").value())
    end)

    it("writes no option it does not document", function()
        -- 'statusline' included: `M.setup()` delegates it to
        -- `util.statusline`, so it is written here without appearing in
        -- this module's own table
        eq(written(require("option.view").setup), names(view, derived))
    end)
end)

describe("option.fold.setup", function()
    ---@type table<string, string | boolean | integer>
    local saved

    before_each(function()
        saved = capture(fold)
    end)
    after_each(function()
        restore(saved)
    end)

    it("applies its documented global option values", function()
        require("option.fold").setup()
        applied(fold)
    end)

    it("writes no option it does not document", function()
        -- Unlike its siblings this module writes through `vim.opt` and
        -- `vim.o`, which reach the same API underneath
        eq(written(require("option.fold").setup), names(fold))
    end)
end)

describe("option.setup", function()
    ---@type table<string, string | boolean | integer>
    local saved

    before_each(function()
        saved = capture(general, view, fold)
    end)
    after_each(function()
        restore(saved)
    end)

    it("applies every sibling module's values", function()
        -- The aggregate is what `init.lua` actually calls, so a sibling
        -- dropped from `option.init` would otherwise go unnoticed
        require("option").setup()
        applied(general)
        applied(view)
        applied(fold)
    end)

    it("writes no option no sibling documents", function()
        -- A sibling added to `option.init` but to no table here would
        -- otherwise be applied by the aggregate and restored by nothing
        eq(
            written(require("option").setup),
            names(general, view, fold, derived)
        )
    end)
end)
