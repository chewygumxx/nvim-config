---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/rules/tests.md
  #
  #

ctime: 2026-09-27
title: The mini.test suite
paths:
  - "tests/**/*"
tags:
  - llm
  - claude
---

# `tests/` shares one Neovim process

Name a test file `test_<module>.lua` with `/` flattened to `_`, so
`lua/util/git.lua` is covered by `tests/test_util_git.lua`.
`tests/test_coverage.lua` derives that mapping mechanically, which means a
conventionally named file needs no registry entry and an unconventional one
needs a `covered_by` entry or an `exempt` entry with a stated reason. An empty
reason is rejected. That file also cross-checks the collection glob, so a
misnamed test cannot sit in `tests/` looking collected.

Load the shared fixtures with `dofile("tests/helpers.lua")` and never `require`.
Nothing puts `tests/` on the Lua module path and nothing should:
`collect.find_files` globs `tests/**/test_*.lua`, so a module named like a test
file would be collected as one. `helpers.lua` is named the way it is to stay
outside that glob.

**The whole suite shares one Neovim process, and files run in alphabetical
order.** Everything below follows from that. Anything mutating session state,
global options, global keymaps, augroups, highlight groups, must capture and
restore it, because whatever is left set is inherited by every file after.
Assert the _whole_ set you write rather than only the documented entries, by
stubbing the writer (`vim.keymap.set`, `nvim_set_option_value`, `nvim_set_hl`,
`nvim_create_augroup`) for the duration of one `setup()` call. The reason is
that the documented list doubles as the restore list, so an entry missing from
it is an entry nothing puts back; that is how a visual-mode `gF` override once
leaked into every later file.

Write a stub with the real arity. A narrower one retypes the field for the whole
workspace and makes every genuine call site report `redundant-parameter`.

Tests that shell out to git build real repositories under `vim.fn.tempname()`
through `helpers.repo()` and delete them in `after_each`. That helper pins what
git would otherwise take from the machine: `branch` is a required argument
rather than a default, since `init.defaultBranch` is not something a test should
inherit, and `user.name`/`user.email` are set per repository because a CI runner
has no global identity and `git commit` fails outright without one.
`helpers.git` raises on a non-zero exit rather than returning an empty string,
since a swallowed setup failure resurfaces later as a puzzling assertion about
something else.

A case about something _not_ happening waits for a fence rather than sleeping.
`util.wip`'s `report` argument exists for this, making the module announce the
no-op it reached; it replaced three fixed `vim.wait(2000, ...)` sleeps that were
half the suite's runtime.

The runner fails closed, and deliberately: `mini.test` ends a run with `cquit 0`
whenever nothing failed, so a run that collected nothing exits 0 and reports
success. Keep it that way.

Several files in `tests/` are about a whole directory rather than one module,
and a change to what they police is a change to a registry rather than to an
assertion. `test_spec.lua` is the smoke test over `lua/spec/` and `lsp/`,
including that every slug in `lua/plugin.lua`'s `elide` and `condemn` lists
names a plugin some spec declares, that `mason-lspconfig`'s `ensure_installed`
holds exactly the servers `lsp/` configures, and that each of those is a whole
configuration that loads with no module missing. `test_coverage.lua` is the
coverage registry described above. `test_filetype_modules.lua` drives the
specialised filetype modules through `filetype.config`, the real dispatcher.
`test_queries.lua` validates `queries/` at three depths, `test_lockfile.lua`
checks `lazy-lock.json` against the spec directory, `test_lazy_integration.lua`
resolves the specs through a real lazy.nvim, and `test_claude_assets.lua` checks
`.claude/` against the tree its prose names.

**Three files run a second Neovim, for different reasons, and none should be
turned into an in-process test.** `test_init.lua` is the one that uses
`MiniTest.new_child_neovim()`, because `init.lua`'s load order cannot be
asserted in a process that has already required half of those modules; the child
starts on `scripts/minimal_init.lua` and has `package.loaded["plugin"]` stubbed
before `init.lua` is sourced, since `plugin.setup()` is the lazy.nvim bootstrap
and would otherwise clone from the network. `test_lazy_integration.lua` instead
spawns `scripts/lazy_merge.lua` through `vim.system` with `XDG_DATA_HOME`,
`XDG_STATE_HOME` and `XDG_CACHE_HOME` pointed at a throwaway profile, because
`stdpath` is fixed at startup and a real lazy.nvim run writes `state.json` and
the lockfile into whichever profile it finds; lazy.nvim and mini.test are
symlinked into that profile rather than cloned.
`test_usercmd_interpret_escape.lua` does the same with `XDG_CACHE_HOME` alone,
for the one case that must write the pre-interpretation copy, since the real
cache directory is no place for a test to leave files.

That second file's own header records what it does and does not catch,
established by mutation: it catches the `M.import()` wiring coming apart and any
change in what lazy.nvim means by `ignore_installed`, and it cannot catch a slug
moved between `elide` and `condemn`, since it reads those lists from the same
module that drove the resolution. Do not read a pass there as covering the
distinction.
