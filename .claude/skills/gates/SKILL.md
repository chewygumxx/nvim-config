---
name: gates
description: >-
  Run or diagnose this repository's lint, format, typecheck and test gates. Use
  when running luafmt, selene, tombi, prettier, ts_query_ls, lua-language-server
  or the mini.test suite, when a gate fails or appears to pass wrongly, when
  .husky/pre-commit or a CI job in .github/workflows/lint-config.yaml behaves
  unexpectedly, or when diagnosing a tool that mise.toml pins.
---

# Gates

There is no build step. Everything below is a check.

## Reaching the toolchain first

mise is not activated in a Claude Code Bash call, so `ts_query_ls` is absent
from `PATH` entirely and `luafmt`, `emmylua_check` and `emmylua_doc_cli` resolve
to `~/.local/share/cargo/bin` rather than to the pin. Source the helper before
running anything:

```sh
. ./.claude/hooks/lib/tools.sh && mise_path
```

`mise exec` is not the way to do this: `mise.toml` pins the editor toolchain
beside the gates, so `mise exec -- ts_query_ls --version` starts installing all
22 tools before it answers. `mise bin-paths` and `mise which` read what is
installed and never reach the network. `selene` is the one tool the prefix does
not redirect, since its install directory is not among the printed bin paths;
use `mise which selene` where the exact version matters.

## Two rules that are easy to get wrong

**Never trust `lua-language-server`'s exit code.** Some releases leave it at 0
with problems found. `.husky/pre-commit` and the `LuaCATS` CI job both read the
`no problems found` summary line instead, and so should you.

**Rerun a cold LuaLS failure once before believing it.** A cold run reports a
spurious problem on an untouched file often enough that it is a known behaviour
rather than a surprise. A second run on the same tree is clean.

The editor's own live diagnostics are a third thing again, and not this check: a
cold or mid-indexing LuaLS reports spurious `undefined-global` on `vim` and
`undefined-doc-name` on real types like `TSNode`. Confirm against the repo-wide
run before acting on either.

## The gates, in the order CI runs them

- **Lua**: `luafmt --check --verify <file>` then `selene <file>`. Configs are
  `.luafmt.toml` and `selene.toml` (`std = "lua51+vim+luajit +busted"`, backed
  by `vim.yml`/`luajit.yml`/`busted.yml`). `selene` is held back from `types/`,
  whose `---@meta` stubs would be flagged for their intentional global
  declarations. Note `selene`'s `lua51` std does not carry `io.stdout`, so a
  script writing to real stdout uses `io.write`.
- **TOML**: `tombi format --check --offline` and
  `tombi lint --error-on-warnings --offline` (`.tombi.toml`).
- **JSON/YAML**: `npx prettier --check <files>`. prettier is configured by the
  `prettier` key inside `package.json` rather than a `.prettierrc`, and
  `.prettierignore` excludes `lazy-lock.json`. prettier reads `.editorconfig`,
  which is why `.luarc.json` is 4-space and passes; there is no `tabWidth`
  anywhere.
- **Tree-sitter queries**: `ts_query_ls format --check queries` and
  `ts_query_ls lint queries` (`.tsqueryrc.json`), the `Queries` job. `lint`
  rather than `check` because it needs no parser objects and so reaches all
  eight files, where `check` would cover only the languages Neovim bundles a
  parser for. A single `format` write pass is not a fixed point, so
  `.husky/pre-commit` runs it twice and then asserts with `--check`;
  `queries/CLAUDE.md` has the rest.
- **Lua typecheck**: `lua-language-server --check=. --checklevel=Warning`,
  repo-wide rather than per-file, needing `VIMRUNTIME` exported so
  `$VIMRUNTIME/lua` in `.luarc.json`'s `workspace.library` resolves.
  `diagnostics.groupFileStatus` enables `luadoc`/`strict`/`strong`/`type-check`
  at `Any`, so annotation drift fails it and not just genuine type errors;
  `missing-fields`, `duplicate-set-field`, `need-check-nil`, `no-unknown` and
  `param-type-mismatch` are the ones that bite.
- **Tests**:
  `nvim --headless -u scripts/minimal_init.lua -l scripts/minitest.lua`.
- **Commit message typecheck**: `npm run typecheck`, running `tsc` scoped to
  `.commitlintrc.mts` only per `tsconfig.json`.

## The test suite

[mini.test](https://github.com/nvim-mini/mini.test), driven through its
busted-style `describe`/`it`/`before_each`/`after_each` wrappers with
`MiniTest.expect.equality` as the assertion.

`scripts/minimal_init.lua` deliberately does not source `init.lua`, and
_replaces_ the runtimepath with this checkout, `$VIMRUNTIME` and the
already-installed `mini.test`. `stdpath("config")` and the site directories are
removed rather than merely outranked: for anyone running the deployed copy of
this config they hold a second copy of every module under test, and a module
deleted or renamed in the checkout would keep resolving from there.

`scripts/minitest.lua` is the single entry point shared by headless runs and
`:MiniTestRun`, and both apply `lua/util/minitest.lua`'s options, so what is
collected and how it executes is the same either way. It fails closed for the
same reason `scripts/luals_untyped.lua` does: `mini.test` ends a run with
`cquit 0` whenever nothing failed, so a run that collected nothing exits 0 and
reports success. It therefore raises unless `lua/util/minitest.lua` is readable
from the cwd and `collect.find_files` returned at least one file.

`MINITEST_PATTERN` narrows a run to the cases whose description matches a Lua
pattern, the headless counterpart of `:MiniTestRunFile`:

```sh
MINITEST_PATTERN=util.wip nvim --headless -u scripts/minimal_init.lua -l scripts/minitest.lua
```

It is a Lua pattern and not a literal, so a `-` in a group name has to be
escaped or avoided.

`mini.test` is pinned by `tag` in `lua/spec/mini.test.lua`, and CI reads that
tag out of the spec rather than naming its own, so the pre-commit gate and CI
cannot run different framework versions.

## Sweeps that are not gates

Neither runs automatically. Both go through Neovim so the child inherits
`$VIMRUNTIME`.

- `nvim --headless -u scripts/minimal_init.lua -l scripts/typecheck_sensitive.lua`
  runs the same repo-wide check at `Hint`, ie. everything the gate ignores. It
  is a sweep to read, not a gate to satisfy.
- `nvim --headless -u scripts/minimal_init.lua -l scripts/luals_untyped.lua`
  fails if LuaLS cannot infer anything more specific than `any`/`unknown` under
  `lua/`, `lsp/` or `init.lua`. Its pass signal is the absence of output, so it
  fails closed: a failed or timed-out `inlayHint` request, a client that never
  finished indexing, an empty file list from the wrong cwd, or a run that saw no
  hints at all is fatal rather than an empty result.

## What `.husky/pre-commit` actually does

It runs `luafmt --write` + `selene`, `tombi format` + `tombi lint`,
`prettier --write`, and `ts_query_ls format` + `ts_query_ls lint` on staged
files matching each type, then re-stages the results. `lintfmt_query` is the one
that formats _before_ it lints, so what is linted is the bytes being committed,
and the one that runs its formatter twice followed by a `--check`, because a
single pass does not converge.

It then gates on two whole-repo checks that ignore what was staged:
`lua-language-server --check` at `Warning` whenever any `*.lua` file is staged,
and the full suite whenever anything under `lua/`, `tests/`, `scripts/`, `lsp/`,
`queries/` or `init.lua` is. Each asks `git diff --cached` for its own file list
rather than reading a variable another function left behind.

**Every tool it cannot find is skipped silently.** That is deliberate and
correct for a hook other people's machines also run, but it is why
`.claude/hooks/require-gates.sh` refuses a commit while a gate binary is absent,
and why CI repeats the LuaLS check rather than trusting the hook.

## The toolchain itself

`mise.toml` is the single place any tool version is named, and `mise install`
provides all of them. It covers the gates and the editor toolchain mason would
otherwise install, because `lua/plugin.lua` condemns the whole mason trio under
Termux and mise is that platform's only supported route to the same binaries.
Backends are named explicitly (`aqua:`, `github:`, `npm:`, `pipx:`, `pypi:`)
rather than relying on registry aliases, so resolution is visible and cannot
change underneath a pin. `ubi:` is deprecated upstream and removed in mise
2027.1.0; use `github:`.

Three binaries (`luafmt`, `emmylua_check`, `emmylua_doc_cli`) come from one
release of `EmmyLuaLs/emmylua-analyzer-rust`, which needs a `[tool_alias]` block
each plus `matching` on the `[tools]` entry. Putting `matching` in the alias
block instead is ignored **silently** and every alias installs the same asset.
When diagnosing one of these three: `mise ls` reporting a tool `(missing)` means
only that its install has not been run, and a `cargo install` of the same
project puts all three in `~/.local/share/cargo/bin`, which shadows mise on
`PATH` and agrees with the pin only until somebody bumps one of them.

CI reads every pin through `.github/scripts/tool_version.py` rather than
restating it, so a workflow cannot silently fall back to whatever the runner
happened to have.
