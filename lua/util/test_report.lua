#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/test_report.lua
--
--

--
-- Per-file and machine-readable views of a `mini.test` run.
--
-- `mini.test`'s own reporters answer "did it pass", which is what a gate
-- needs and all this repository asked of them until now. What they cannot
-- answer is where the run spent its time, and a reporter is the only place
-- that answer exists: `MiniTest.execute` calls `reporter.update(case_num)`
-- after every state change, so the boundary between two cases is already
-- being announced once per case and nothing was listening.
--
-- Everything here composes rather than replaces. `gen_reporter.stdout()`
-- still writes the progress line and the fail block, which is why a run
-- with neither environment variable set is byte-identical to one from
-- before this module existed.
--
-- Split into pure renderers (`timed`, `totals`, `slowest`, `junit`,
-- `markdown`) and one impure factory (`reporter`), for the reason
-- `lua/util/vimdoc.lua` and `scripts/genhelp.lua` are split: the renderers
-- are what a test can assert on without a suite running underneath it.
--

local M = {}

--- One executed case, flattened to what the renderers below take.
---@class cgxx.test_report.Timed
---@field file  string   Test file the case was collected from
---@field name  string   Its `describe`/`it` descriptions, joined
---@field ms    number   Wall time in milliseconds
---@field fails string[] Assertion failures; empty when the case passed
---@field notes string[] `MiniTest.add_note` messages

--- Per-file aggregate of the above.
---@class cgxx.test_report.Total
---@field file  string
---@field cases integer
---@field fails integer Cases that failed, not failures
---@field ms    number

--- Options for `M.reporter`.
---@class cgxx.test_report.Opts
---@field xml?      string             JUnit XML path; nil writes none
---@field summary?  string             Markdown path appended to; nil none
---@field slowest?  integer            Slow cases to print (default: 10)
---@field quit?     boolean            Whether `finish` exits (default: true)
---@field delegate? mini.test.Reporter Reporter to wrap (default: stdout's)

--- Flattens an executed case into a `Timed`.
---
--- A case that never ran has no `exec` at all, which is not the same as one
--- that ran and passed; both flatten to zero failures here, since the
--- delegate reporter is what reports the distinction.
---@param case MiniTest.Case
---@param ms   number        Wall time in milliseconds
---@return cgxx.test_report.Timed timed
M.timed = function(case, ms)
    local exec = case.exec or { fails = {}, notes = {} }

    ---@type string[]
    local trail = {}
    for i = 2, #case.desc do
        trail[#trail + 1] = case.desc[i]
    end

    return {
        file  = case.desc[1] or "?",
        name  = #trail > 0 and table.concat(trail, " | ") or "(file)",
        ms    = ms,
        fails = exec.fails,
        notes = exec.notes,
    }
end

--- Per-file totals, in the order the files first appear, ie. the order
--- they ran in.
---@param cases cgxx.test_report.Timed[]
---@return cgxx.test_report.Total[] totals
M.totals = function(cases)
    ---@type cgxx.test_report.Total[]
    local order = {}
    ---@type table<string, cgxx.test_report.Total>
    local index = {}

    for _, case in ipairs(cases) do
        local total = index[case.file]
        if not total then
            total             = {
                file  = case.file,
                cases = 0,
                fails = 0,
                ms    = 0,
            }
            index[case.file]  = total
            order[#order + 1] = total
        end
        total.cases = total.cases + 1
        total.ms    = total.ms + case.ms
        if #case.fails > 0 then
            total.fails = total.fails + 1
        end
    end

    return order
end

--- The n slowest cases, slowest first.
---
--- File then name break a tie rather than leaving it to `table.sort`, which
--- is not stable: two cases at the same millisecond would otherwise swap
--- places between runs and make the output look like it had changed.
---@param cases cgxx.test_report.Timed[]
---@param n     integer
---@return cgxx.test_report.Timed[] slowest
M.slowest = function(cases, n)
    ---@type cgxx.test_report.Timed[]
    local sorted = {}
    for _, case in ipairs(cases) do
        sorted[#sorted + 1] = case
    end

    table.sort(sorted, function(a, b)
        if a.ms ~= b.ms then
            return a.ms > b.ms
        end
        if a.file ~= b.file then
            return a.file < b.file
        end
        return a.name < b.name
    end)

    while #sorted > n do
        table.remove(sorted)
    end
    return sorted
end

---@type table<string, string>
local entity = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&apos;",
}

--- Escapes text for an XML attribute or text node.
---
--- Control characters go too, not only the five entities. A failure message
--- can carry whatever the code under test printed, and an XML parser
--- rejects a stray control byte outright rather than reporting a line
--- number worth reading.
---@param text string
---@return string escaped
local escape = function(text)
    ---@type string
    local escaped = text:gsub("[&<>\"']", entity)
    ---@type string
    local clean = escaped:gsub("%c", function(char)
        if char == "\n" or char == "\t" then
            return char
        end
        return " "
    end)
    return clean
end

--- Renders the run as JUnit XML, one `testsuite` per test file.
---
--- JUnit rather than TAP: GitHub, and every other CI this might ever run
--- on, parses the former without a plugin, and TAP would carry strictly
--- less (no per-case time, no suite grouping).
---@param cases cgxx.test_report.Timed[]
---@return string[] lines
M.junit = function(cases)
    local totals = M.totals(cases)

    local all_ms, all_fails = 0, 0
    for _, total in ipairs(totals) do
        all_ms    = all_ms + total.ms
        all_fails = all_fails + total.fails
    end

    -- Bound out of the literal below so neither line needs a concatenation
    -- `luafmt` would rejoin past 80 columns
    local counts = string.format(
        'tests="%d" failures="%d" time="%.3f"',
        #cases,
        all_fails,
        all_ms / 1000
    )

    ---@type string[]
    local lines = {
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<testsuites name="nvim-config" ' .. counts .. ">",
    }

    for _, total in ipairs(totals) do
        lines[#lines + 1] = string.format(
            '    <testsuite name="%s" tests="%d" failures="%d" time="%.3f">',
            escape(total.file),
            total.cases,
            total.fails,
            total.ms / 1000
        )

        for _, case in ipairs(cases) do
            if case.file == total.file then
                local open = string.format(
                    '        <testcase name="%s" classname="%s" time="%.3f"',
                    escape(case.name),
                    escape(case.file),
                    case.ms / 1000
                )
                if #case.fails == 0 then
                    lines[#lines + 1] = open .. " />"
                else
                    -- Bound first: `gsub` returns a count as its second
                    -- value, which `escape` would read as a parameter
                    ---@type string
                    local first       = case.fails[1]:gsub("\n.*", "")
                    lines[#lines + 1] = open .. ">"
                    lines[#lines + 1] = string.format(
                        '            <failure message="%s">%s</failure>',
                        escape(first),
                        escape(table.concat(case.fails, "\n"))
                    )
                    lines[#lines + 1] = "        </testcase>"
                end
            end
        end

        lines[#lines + 1] = "    </testsuite>"
    end

    lines[#lines + 1] = "</testsuites>"
    return lines
end

--- Renders the run as Markdown, for a CI job summary.
---@param cases cgxx.test_report.Timed[]
---@return string[] lines
M.markdown = function(cases)
    ---@type string[]
    local lines = {
        "### mini.test",
        "",
        "| File | Cases | Fails | Time |",
        "| --- | --: | --: | --: |",
    }

    local all_ms, all_fails = 0, 0
    for _, total in ipairs(M.totals(cases)) do
        all_ms            = all_ms + total.ms
        all_fails         = all_fails + total.fails
        lines[#lines + 1] = string.format(
            "| `%s` | %d | %d | %.0fms |",
            total.file,
            total.cases,
            total.fails,
            total.ms
        )
    end

    lines[#lines + 1] = string.format(
        "| **Total** | **%d** | **%d** | **%.0fms** |",
        #cases,
        all_fails,
        all_ms
    )

    vim.list_extend(lines, {
        "",
        "#### Slowest cases",
        "",
        "| Case | Time |",
        "| --- | --: |",
    })
    for _, case in ipairs(M.slowest(cases, 10)) do
        lines[#lines + 1] = string.format(
            "| `%s` %s | %.0fms |",
            case.file,
            case.name,
            case.ms
        )
    end

    return lines
end

--- Builds the reporter `execute.reporter` takes.
---
--- Composed over `gen_reporter.stdout()` rather than written from scratch,
--- so the progress line and the fail block stay exactly as they were.
---
--- The delegate is built with `quit_on_finish = false` and the `cquit` is
--- issued here instead, for two reasons that arrived together: a sweep
--- layered on top of this needs to fail the process for a reason of its own
--- after the suite itself has passed, and a test of this module has to be
--- able to call `finish` without ending the run it is part of.
---
--- `opts.delegate` exists for that second reason too. The stdout reporter
--- writes to the same stdout the suite running this module's own test is
--- reporting on, so a test that did not substitute it would interleave a
--- second progress line into the first.
---@param opts cgxx.test_report.Opts
---@return mini.test.Reporter reporter
M.reporter = function(opts)
    local delegate = opts.delegate
    if not delegate then
        ---@type mini.test
        local mini = require("mini.test")
        delegate   = mini.gen_reporter.stdout({ quit_on_finish = false })
    end

    ---@type MiniTest.Case[]
    local all = {}
    --- Latest `update` time per case number. `update` is called more than
    --- once per case, and the last call for case n is the boundary between
    --- it and case n+1, which is what makes a difference of two stamps the
    --- case's own time.
    ---@type table<integer, integer>
    local stamp   = {}
    local started = vim.uv.hrtime()

    ---@param cases MiniTest.Case[]
    ---@return nil
    local start = function(cases)
        all     = cases
        started = vim.uv.hrtime()
        if delegate.start then
            delegate.start(cases)
        end
    end

    ---@param case_num integer
    ---@return nil
    local update = function(case_num)
        stamp[case_num] = vim.uv.hrtime()
        if delegate.update then
            delegate.update(case_num)
        end
    end

    ---@return nil
    local finish = function()
        ---@type cgxx.test_report.Timed[]
        local timed = {}
        ---@type integer
        local previous = started
        for num, case in ipairs(all) do
            ---@type integer
            local at          = stamp[num] or previous
            timed[#timed + 1] = M.timed(case, (at - previous) / 1e6)
            ---@type integer
            previous = at
        end

        if opts.xml then
            vim.fn.writefile(M.junit(timed), opts.xml)
        end
        if opts.summary then
            vim.fn.writefile(M.markdown(timed), opts.summary, "a")
        end

        if delegate.finish then
            delegate.finish()
        end

        local top = opts.slowest or 10
        if top > 0 then
            io.write("\nSlowest cases\n")
        end
        for _, case in ipairs(M.slowest(timed, top)) do
            io.write(
                string.format(
                    "  %6.0fms  %s %s\n",
                    case.ms,
                    case.file,
                    case.name
                )
            )
        end

        if opts.quit == false then
            return
        end

        local failed = false
        for _, case in ipairs(timed) do
            if #case.fails > 0 then
                failed = true
            end
        end
        vim.cmd(string.format("silent! %dcquit", failed and 1 or 0))
    end

    return { start = start, update = update, finish = finish }
end

--- The reporter a headless run of this repository uses, or nil for the
--- framework's own choice.
---
--- nil interactively, so `:MiniTestRun` keeps the buffer reporter. nil when
--- neither output path is named, so the default gate is unchanged. nil
--- while `MINITEST_PATTERN` narrows the run, because a report covering
--- three files would otherwise overwrite one covering all of them and look
--- like the suite had shrunk.
---@return mini.test.Reporter? reporter
M.from_env = function()
    if #vim.api.nvim_list_uis() > 0 then
        return nil
    end

    -- Bound to a typed local: `vim.env` indexes to `any`, which the
    -- annotation-coverage gate counts as untyped
    ---@type table<string, string?>
    local environ = vim.env
    local xml     = environ.MINITEST_REPORT or ""
    local summary = environ.MINITEST_SUMMARY or ""

    local asked    = xml ~= "" or summary ~= ""
    local narrowed = (environ.MINITEST_PATTERN or "") ~= ""
    if not asked or narrowed then
        return nil
    end

    return M.reporter({
        xml     = xml ~= "" and xml or nil,
        summary = summary ~= "" and summary or nil,
    })
end

return M
