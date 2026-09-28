#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_test_report.lua
--
--

--
-- The renderers are asserted directly, on hand-built `Timed` tables rather
-- than on a real run: a report of this suite would have to contain this
-- file's own cases, so it could not be compared against anything fixed.
--
-- `reporter` is driven through a whole start/update/finish cycle, which is
-- only safe because the delegate is substituted and `quit` is off. With the
-- real delegate, `finish` writes a second progress line into the one this
-- file is being reported on, and then ends the process with `cquit`.
--

local report = require("util.test_report")
---@type mini.test
local MiniTest = require("mini.test")
local eq       = MiniTest.expect.equality

--- A `Timed` with the fields a case needs and nothing more.
---@param file   string
---@param name   string
---@param ms     number
---@param fails? string[]
---@return cgxx.test_report.Timed timed
local function timed(file, name, ms, fails)
    return {
        file  = file,
        name  = name,
        ms    = ms,
        fails = fails or {},
        notes = {},
    }
end

describe("util.test_report.timed", function()
    it("splits the file off the descriptions and joins the rest", function()
        local case = report.timed({
            desc = { "tests/test_x.lua", "group", "does a thing" },
            exec = { fails = {}, notes = {} },
        }, 12)
        eq(case.file, "tests/test_x.lua")
        eq(case.name, "group | does a thing")
        eq(case.ms, 12)
    end)

    it("tolerates a case that never ran", function()
        -- `exec` is nil until `MiniTest.execute` reaches the case, and a
        -- run stopped early leaves the rest of them that way
        local case = report.timed({ desc = { "tests/test_x.lua" } }, 0)
        eq(case.name, "(file)")
        eq(case.fails, {})
        eq(case.notes, {})
    end)
end)

describe("util.test_report.totals", function()
    it("aggregates per file, in the order the files ran", function()
        local totals = report.totals({
            timed("b.lua", "one", 5),
            timed("a.lua", "two", 3),
            timed("b.lua", "three", 2),
        })
        eq(#totals, 2)
        eq({ totals[1].file, totals[1].cases, totals[1].ms }, { "b.lua", 2, 7 })
        eq({ totals[2].file, totals[2].cases, totals[2].ms }, { "a.lua", 1, 3 })
    end)

    it("counts a failed case once, not once per failure", function()
        local totals = report.totals({
            timed("a.lua", "one", 1, { "first", "second" }),
            timed("a.lua", "two", 1),
        })
        eq({ totals[1].cases, totals[1].fails }, { 2, 1 })
    end)
end)

describe("util.test_report.slowest", function()
    it("returns the n slowest, slowest first", function()
        local slow = report.slowest({
            timed("a.lua", "quick", 1),
            timed("a.lua", "slow", 30),
            timed("a.lua", "middling", 10),
        }, 2)
        eq(#slow, 2)
        eq({ slow[1].name, slow[2].name }, { "slow", "middling" })
    end)

    it("breaks a tie on file then name, so the order is fixed", function()
        -- `table.sort` is not stable, so equal times would otherwise land
        -- in whichever order the implementation happened to produce and
        -- make an unchanged report look changed
        local slow = report.slowest({
            timed("b.lua", "a", 1),
            timed("a.lua", "b", 1),
            timed("a.lua", "a", 1),
        }, 3)
        eq({
            slow[1].file .. slow[1].name,
            slow[2].file .. slow[2].name,
            slow[3].file .. slow[3].name,
        }, { "a.luaa", "a.luab", "b.luaa" })
    end)

    it("returns everything when asked for more than it has", function()
        eq(#report.slowest({ timed("a.lua", "only", 1) }, 10), 1)
    end)
end)

describe("util.test_report.junit", function()
    it("groups cases into one testsuite per file", function()
        local lines = report.junit({
            timed("a.lua", "one", 1000),
            timed("b.lua", "two", 500),
        })
        local xml   = table.concat(lines, "\n")
        eq(xml:find('<testsuites name="nvim%-config" tests="2"') ~= nil, true)
        eq(xml:find('<testsuite name="a.lua" tests="1"') ~= nil, true)
        eq(xml:find('<testsuite name="b.lua" tests="1"') ~= nil, true)
        -- Milliseconds in, seconds out: JUnit's `time` is seconds
        eq(xml:find('time="1.000"') ~= nil, true)
    end)

    it("self-closes a passing case and opens a failing one", function()
        local lines = report.junit({
            timed("a.lua", "passes", 1),
            timed("a.lua", "fails", 1, { "wanted 1, got 2" }),
        })
        local xml   = table.concat(lines, "\n")
        eq(xml:find('name="passes".-/>') ~= nil, true)
        eq(xml:find("<failure message=\"wanted 1, got 2\">") ~= nil, true)
        eq(xml:find('failures="1"') ~= nil, true)
    end)

    it("takes the first line of a failure as its message", function()
        local lines = report.junit({
            timed("a.lua", "fails", 1, { "summary\nstack trace" }),
        })
        local xml   = table.concat(lines, "\n")
        eq(xml:find('message="summary"') ~= nil, true)
        -- The body keeps the whole thing
        eq(xml:find("summary\nstack trace") ~= nil, true)
    end)

    it("escapes the five entities and flattens control bytes", function()
        local lines = report.junit({
            timed("a.lua", "a<b>&c\"d'e\27[0mf", 1),
        })
        local xml   = table.concat(lines, "\n")
        local want  = "a&lt;b&gt;&amp;c&quot;d&apos;e %[0mf"
        eq(xml:find(want) ~= nil, true)
    end)
end)

describe("util.test_report.markdown", function()
    it("totals every case under the per-file rows", function()
        local lines = report.markdown({
            timed("a.lua", "one", 1),
            timed("b.lua", "two", 2),
        })
        local md    = table.concat(lines, "\n")
        eq(md:find("| `a.lua` | 1 | 0 | 1ms |", 1, true) ~= nil, true)
        eq(md:find("| %*%*Total%*%* | %*%*2%*%*") ~= nil, true)
        eq(md:find("#### Slowest cases", 1, true) ~= nil, true)
    end)
end)

describe("util.test_report.reporter", function()
    ---@type string
    local path

    before_each(function()
        path = vim.fn.tempname()
    end)

    after_each(function()
        vim.fn.delete(path)
    end)

    it("delegates all three calls and writes the XML on finish", function()
        ---@type string[]
        local seen = {}
        ---@type mini.test.Reporter
        local delegate = {
            start = function(cases)
                seen[#seen + 1] = "start:" .. #cases
            end,
            update = function(case_num)
                seen[#seen + 1] = "update:" .. case_num
            end,
            finish = function()
                seen[#seen + 1] = "finish"
            end,
        }

        local reporter = report.reporter({
            xml      = path,
            slowest  = 0,
            quit     = false,
            delegate = delegate,
        })

        local start  = assert(reporter.start, "reporter has no start")
        local update = assert(reporter.update, "reporter has no update")
        local finish = assert(reporter.finish, "reporter has no finish")

        start({
            { desc = { "a.lua", "one" }, exec = { fails = {}, notes = {} } },
            { desc = { "a.lua", "two" }, exec = { fails = {}, notes = {} } },
        })
        update(1)
        update(2)
        finish()

        eq(seen, { "start:2", "update:1", "update:2", "finish" })
        eq(vim.fn.filereadable(path), 1)
        local xml = table.concat(vim.fn.readfile(path), "\n")
        eq(xml:find('tests="2"', 1, true) ~= nil, true)
    end)

    it("writes no XML when no path was named", function()
        local reporter = report.reporter({
            slowest  = 0,
            quit     = false,
            delegate = {},
        })
        local finish   = assert(reporter.finish, "reporter has no finish")
        finish()
        eq(vim.fn.filereadable(path), 0)
    end)
end)

describe("util.test_report.from_env", function()
    ---@type string?
    local report_path
    ---@type string?
    local summary_path
    ---@type string?
    local pattern

    before_each(function()
        -- Captured and restored: the whole suite shares one process, and
        -- `MINITEST_PATTERN` in particular decides what the *current* run
        -- collected, so leaving one set would filter every later file
        ---@type table<string, string?>
        local environ = vim.env
        report_path   = environ.MINITEST_REPORT
        summary_path  = environ.MINITEST_SUMMARY
        pattern       = environ.MINITEST_PATTERN
    end)

    after_each(function()
        vim.env.MINITEST_REPORT  = report_path
        vim.env.MINITEST_SUMMARY = summary_path
        vim.env.MINITEST_PATTERN = pattern
    end)

    it("declines when neither output path is named", function()
        vim.env.MINITEST_REPORT  = nil
        vim.env.MINITEST_SUMMARY = nil
        vim.env.MINITEST_PATTERN = nil
        eq(report.from_env(), nil)
    end)

    it("builds one when a path is named", function()
        vim.env.MINITEST_REPORT  = "/dev/null"
        vim.env.MINITEST_SUMMARY = nil
        vim.env.MINITEST_PATTERN = nil
        eq(type(report.from_env()), "table")
    end)

    it("declines while MINITEST_PATTERN narrows the run", function()
        -- A report of three files would otherwise overwrite one of all of
        -- them and read as the suite having shrunk
        vim.env.MINITEST_REPORT  = "/dev/null"
        vim.env.MINITEST_PATTERN = "util.text"
        eq(report.from_env(), nil)
    end)
end)
