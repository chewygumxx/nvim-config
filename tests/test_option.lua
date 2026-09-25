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
-- These apply real global options (the same ones `init.lua` applies at
-- startup), so they intentionally mutate session state rather than being
-- pure. Safe to run in any order since every case sets the same values.
--

local eq = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

describe("option.general.setup", function()
    it("applies its documented global option values", function()
        require("option.general").setup()
        eq(vim.o.clipboard, "unnamedplus")
        eq(vim.o.expandtab, true)
        eq(vim.o.shiftwidth, 4)
        eq(vim.o.tabstop, 4)
        eq(vim.o.ignorecase, true)
        eq(vim.o.smartcase, true)
        eq(vim.o.spelllang, "en")
    end)
end)

describe("option.view.setup", function()
    it("applies its documented global option values", function()
        require("option.view").setup()
        eq(vim.o.termguicolors, true)
        eq(vim.o.number, true)
        eq(vim.o.relativenumber, true)
        eq(vim.o.scrolloff, 5)
        eq(vim.o.splitright, true)
        eq(vim.o.jumpoptions, "view")
    end)

    it("installs the git-aware statusline", function()
        require("option.view").setup()
        eq(vim.o.statusline, require("util.statusline").value())
    end)
end)
