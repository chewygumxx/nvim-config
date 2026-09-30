#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_yamllint.lua
--
--

--
-- nvim-lint is not on the suite's runtimepath, so these drive
-- `util.yamllint` directly: the directory it picks, the parser, and,
-- where yamllint is installed, a real run that has to find a
-- repository's `.yamllint.yaml` from that directory alone.
--

local yamllint = require("util.yamllint")
---@type mini.test
local MiniTest = require("mini.test")
local eq       = MiniTest.expect.equality

--- A buffer named `path`, left unloaded so nothing is read from disk.
---@param path string
---@return integer
local named = function(path)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, path)
    return buf
end

describe("util.yamllint.cwd", function()
    ---@type string
    local root

    before_each(function()
        root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/sub", "p")
    end)

    after_each(function()
        vim.fn.delete(root, "rf")
    end)

    it("runs from the directory holding the configuration", function()
        vim.fn.writefile({}, root .. "/.yamllint.yaml")
        local buf = named(root .. "/sub/x.yaml")
        eq(yamllint.cwd(buf), root)
        eq(yamllint.path(buf), "sub/x.yaml")
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("runs from the buffer's own directory without one", function()
        local buf = named(root .. "/sub/x.yaml")
        eq(yamllint.cwd(buf), root .. "/sub")
        eq(yamllint.path(buf), "x.yaml")
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("has none for a buffer with no file", function()
        local buf = vim.api.nvim_create_buf(false, true)
        eq(yamllint.cwd(buf), nil)
        vim.api.nvim_buf_delete(buf, { force = true })
    end)
end)

describe("util.yamllint.parse", function()
    ---@type integer
    local buf

    before_each(function()
        buf = named("/tmp/re:po/x.yaml")
    end)

    after_each(function()
        vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("reads positions, severity and rule", function()
        local output = table.concat({
            "/tmp/re:po/x.yaml:1:4: [warning] truthy value (truthy)",
            "/tmp/re:po/x.yaml:2:5: [error] too many spaces (colons)",
        }, "\n")
        local got    = yamllint.parse(output, buf)
        eq(#got, 2)
        eq({ got[1].lnum, got[1].col, got[1].code }, { 0, 3, "truthy" })
        eq(got[1].severity, vim.diagnostic.severity.WARN)
        eq(got[2].severity, vim.diagnostic.severity.ERROR)
        eq(got[2].message, "too many spaces")
    end)

    it("resolves a relative path against where it ran", function()
        local output = "x.yaml:1:1: [error] bad (syntax)"
        eq(#yamllint.parse(output, buf, "/tmp/re:po"), 1)
    end)

    it("drops lines about another file", function()
        local output = "/tmp/other/y.yaml:1:1: [error] bad (syntax)"
        eq(yamllint.parse(output, buf), {})
    end)

    it("hands yamllint a path instead of stdin", function()
        eq(yamllint.linter.stdin, false)
        eq(yamllint.linter.append_fname, false)
        eq(vim.tbl_contains(yamllint.linter.args, "-"), false)
    end)
end)

describe("util.yamllint against a real repository", function()
    ---@type string
    local root

    ---@type integer[]
    local bufs

    before_each(function()
        if vim.fn.executable("yamllint") ~= 1 then
            MiniTest.skip("yamllint is not installed")
        end
        root = vim.fn.tempname()
        bufs = {}
        vim.fn.mkdir(root .. "/sub/gen", "p")
        vim.fn.writefile({
            "extends: default",
            "rules:",
            "  document-start: disable",
            "ignore: |",
            "  sub/gen/",
        }, root .. "/.yamllint.yaml")
        local body = { "a: yes" }
        vim.fn.writefile(body, root .. "/sub/x.yaml")
        vim.fn.writefile(body, root .. "/sub/gen/y.yaml")
    end)

    after_each(function()
        for _, buf in ipairs(bufs or {}) do
            vim.api.nvim_buf_delete(buf, { force = true })
        end
        if root then
            vim.fn.delete(root, "rf")
        end
    end)

    --- Runs yamllint on `path` the way nvim-lint would: `args`
    --- evaluated with the buffer current, from `util.yamllint.cwd`.
    ---@param path string
    ---@return vim.Diagnostic[]
    local lint = function(path)
        local buf = named(path)
        table.insert(bufs, buf)
        local cmd = { yamllint.linter.cmd }
        vim.api.nvim_buf_call(buf, function()
            for _, arg in ipairs(yamllint.linter.args) do
                table.insert(cmd, type(arg) == "function" and arg() or arg)
            end
        end)
        local cwd = yamllint.cwd(buf)
        local run = vim.system(cmd, { cwd = cwd }):wait()
        return yamllint.parse(run.stdout or "", buf, cwd)
    end

    it("applies the repository's rules from a subdirectory", function()
        ---@type string[]
        local codes = {}
        for _, d in ipairs(lint(root .. "/sub/x.yaml")) do
            table.insert(codes, d.code)
        end
        eq(codes, { "truthy" })
    end)

    it("honours the configuration's ignore patterns", function()
        eq(lint(root .. "/sub/gen/y.yaml"), {})
    end)
end)
