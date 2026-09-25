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
-- keep in step.
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

--- Asserts that every option in want holds its expected value, naming the
--- option in the comparison so a failure says which one it was.
---@param want table<string, string | boolean | integer>
---@return nil
local applied = function(want)
    for name, value in pairs(want) do
        eq({ name, get(name) }, { name, value })
    end
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
end)
