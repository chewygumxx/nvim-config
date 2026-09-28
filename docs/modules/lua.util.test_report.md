# global lua.util.test_report








---

## methods
---

### M.timed
---
```lua
function M.timed(
  case: MiniTest.Case,
  ms: number
) -> timed cgxx.test_report.Timed {
    file = string,
    name = string,
    ms = number,
    fails = string[],
    notes = string[],
}
```
@param `ms` - Wall time in milliseconds






Flattens an executed case into a `Timed`.

A case that never ran has no `exec` at all, which is not the same as one
that ran and passed; both flatten to zero failures here, since the
delegate reporter is what reports the distinction.








### M.totals
---
```lua
function M.totals(cases: cgxx.test_report.Timed[]) -> totals cgxx.test_report.Total[]
```





Per-file totals, in the order the files first appear, ie. the order
they ran in.








### M.slowest
---
```lua
function M.slowest(
  cases: cgxx.test_report.Timed[],
  n: integer
) -> slowest cgxx.test_report.Timed[]
```





The n slowest cases, slowest first.

File then name break a tie rather than leaving it to `table.sort`, which
is not stable: two cases at the same millisecond would otherwise swap
places between runs and make the output look like it had changed.








### M.junit
---
```lua
function M.junit(cases: cgxx.test_report.Timed[]) -> lines string[]
```





Renders the run as JUnit XML, one `testsuite` per test file.

JUnit rather than TAP: GitHub, and every other CI this might ever run
on, parses the former without a plugin, and TAP would carry strictly
less (no per-case time, no suite grouping).








### M.markdown
---
```lua
function M.markdown(cases: cgxx.test_report.Timed[]) -> lines string[]
```





Renders the run as Markdown, for a CI job summary.








### M.reporter
---
```lua
function M.reporter(opts: cgxx.test_report.Opts {
    xml = string?,
    summary = string?,
    slowest = integer?,
    quit = boolean?,
    delegate = mini.test.Reporter?,
}) -> reporter mini.test.Reporter
```





Builds the reporter `execute.reporter` takes.

Composed over `gen_reporter.stdout()` rather than written from scratch,
so the progress line and the fail block stay exactly as they were.

The delegate is built with `quit_on_finish = false` and the `cquit` is
issued here instead, for two reasons that arrived together: a sweep
layered on top of this needs to fail the process for a reason of its own
after the suite itself has passed, and a test of this module has to be
able to call `finish` without ending the run it is part of.

`opts.delegate` exists for that second reason too. The stdout reporter
writes to the same stdout the suite running this module's own test is
reporting on, so a test that did not substitute it would interleave a
second progress line into the first.








### M.from_env
---
```lua
function M.from_env() -> reporter mini.test.Reporter?
```





The reporter a headless run of this repository uses, or nil for the
framework's own choice.

nil interactively, so `:MiniTestRun` keeps the buffer reporter. nil when
neither output path is named, so the default gate is unchanged. nil
while `MINITEST_PATTERN` narrows the run, because a report covering
three files would otherwise overwrite one covering all of them and look
like the suite had shrunk.











