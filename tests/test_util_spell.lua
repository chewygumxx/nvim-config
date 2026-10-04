#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_spell.lua
--
--

local spell = require("util.spell")
---@type mini.test
local MiniTest = require("mini.test")
local eq       = MiniTest.expect.equality

---@type string
local dir
---@type string
local saved_spellfile

--- Sets path's modification time, in whole seconds since the epoch.
---@param path  string
---@param mtime integer
---@return nil
local touch = function(path, mtime)
    assert(vim.uv.fs_utime(path, mtime, mtime))
end

describe("util.spell", function()
    before_each(function()
        dir = vim.fn.tempname()
        vim.fn.mkdir(dir, "p")
        saved_spellfile = vim.bo.spellfile
    end)

    after_each(function()
        vim.bo.spellfile = saved_spellfile
        vim.fn.delete(dir, "rf")
    end)

    it("expands every entry in 'spellfile'", function()
        vim.bo.spellfile = dir .. "/a.utf-8.add," .. dir .. "/b.utf-8.add"
        eq(spell.files(), { dir .. "/a.utf-8.add", dir .. "/b.utf-8.add" })
    end)

    it("treats a missing word list as never stale", function()
        eq(spell.stale(dir .. "/none.utf-8.add"), false)
    end)

    it("treats a word list with no .spl as stale", function()
        local add = dir .. "/en.utf-8.add"
        vim.fn.writefile({ "chewygumxx" }, add)
        eq(spell.stale(add), true)
    end)

    it("compares modification times", function()
        local add = dir .. "/en.utf-8.add"
        vim.fn.writefile({ "chewygumxx" }, add)
        vim.fn.writefile({}, add .. ".spl")
        touch(add, 1000)
        touch(add .. ".spl", 2000)
        eq(spell.stale(add), false)
        touch(add, 3000)
        eq(spell.stale(add), true)
    end)

    -- The symptom this module exists for: a word written into the list as
    -- a file, rather than through `zg`, is recognised once refreshed
    it("recompiles a hand-edited word list so its words are good", function()
        local add = dir .. "/en.utf-8.add"
        vim.fn.writefile({ "qwzxbadword" }, add)
        vim.bo.spellfile = add

        eq(spell.refresh(), { add })
        eq(spell.stale(add), false)
        eq(spell.refresh(), {})

        local saved_spell = vim.wo.spell
        vim.wo.spell      = true
        eq(vim.fn.spellbadword("qwzxbadword"), { "", "" })
        vim.wo.spell = saved_spell
    end)
end)
