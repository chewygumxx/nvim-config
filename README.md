---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/README.md
  #
  #

ctime: 2026-09-26
title: nvim-config
description: >-
  A standalone Neovim configuration, plugin-managed by lazy.nvim, gated by a
  mini.test suite and a repo-wide LuaLS typecheck.
tags:
  - nvim
  - lua
  - config
---

# nvim-config

A standalone Neovim configuration. It is its own repository rather than a
directory inside a dotfiles tree: it has its own git history, its own commitlint
and CI setup, and no chezmoi involvement.

Plugins are managed by [lazy.nvim](https://lazy.folke.io), language servers by
Neovim's native `vim.lsp.config`, and every tool version by
[mise](https://mise.jdx.dev). The test suite is
[mini.test](https://github.com/nvim-mini/mini.test), currently 628 cases.

## Requirements

- **Neovim 0.12.5 or later.** `mise.toml` pins the exact release CI runs, and
  the configuration uses 0.11+ APIs throughout (`vim.lsp.config`,
  `vim.lsp.enable`).
- **git**, for the plugin manager, the statusline's repository notation, and the
  WIP snapshot feature.
- **`mise`**, for everything else. One command installs every tool this
  repository names:

```sh
mise install
```

That covers two different sets in one file, deliberately. The first is the gates
(`luafmt`, `selene`, `tombi`, `lua-language-server`, Neovim itself). The second
is the editor toolchain mason would otherwise fetch: language servers, linters,
formatters, debug adapters and `universal-ctags`. The editor half is listed for
a specific reason, which is Termux: `lua/plugin.lua` switches the whole mason
trio off there, because Termux has no toolchain for it, so `mise` is that
platform's only supported route to the same binaries.

## Layout

```
init.lua                 Entry point; calls setup() per top-level module
lua/option/              Vim options, including the statusline install
lua/keymap/              Global mappings
lua/filetype/            Custom detection, plus one module per filetype
lua/autocmd.lua          Augroups and autocommands
lua/usercmd/             User commands, each delegating to a feature module
lua/plugin.lua           Which plugins are enabled, disabled, or installed-but-unloaded
lua/spec/                One lazy.nvim spec per plugin, named for the plugin
lua/util/                Shared helpers: git, headers, WIP snapshots, statusline, ...
lsp/                     One config per language server (runtimepath convention)
queries/                 Tree-sitter queries that replace the runtime ones
snippets/                friendly-snippets-style manifest and per-language JSON
types/                   ---@meta stubs for what LuaLS cannot see on its own
tests/                   The mini.test suite, one file per module under test
scripts/                 Headless entry points: test runner, typecheck sweeps
docs/                    Generated LuaCATS reference; never edited by hand
doc/                     Generated :help and its tags; never edited by hand
spell/                   Compiled spell file
.claude/                 Agent tooling: hooks, skills, commands, long-form reference
```

`init.lua` loads those modules in a deliberate order, documented inline there:
`option`, `keymap`, `filetype` (after both, so its `FileType` overrides win),
`autocmd`, `usercmd`, then `plugin` (after the mappings, filetypes and augroups
its specs key off), and `highlight` last, so it outranks whatever the
colourscheme and Tree-sitter set.

## Checks

Every gate below runs from the repository root. `.husky/pre-commit` runs the
formatters and linters over staged files, then the Lua typecheck and the test
suite over the whole repository regardless of what was staged. Annotation
coverage and the generated documentation are checked by CI only.

| What                | Command                                                                      |
| ------------------- | ---------------------------------------------------------------------------- |
| Lua format          | `luafmt --check --verify <file>.lua`                                         |
| Lua lint            | `selene <file>.lua`                                                          |
| TOML                | `tombi format --check --offline && tombi lint --error-on-warnings --offline` |
| JSON, YAML          | `npx prettier --check <files>`                                               |
| Query format        | `ts_query_ls format --check queries`                                         |
| Query lint          | `ts_query_ls lint queries`                                                   |
| Lua typecheck       | `lua-language-server --check=. --checklevel=Warning`                         |
| Tests               | `nvim --headless -u scripts/minimal_init.lua -l scripts/minitest.lua`        |
| Annotation coverage | `nvim --headless -u scripts/minimal_init.lua -l scripts/luals_untyped.lua`   |
| Generated docs      | `nvim --headless -u scripts/minimal_init.lua -l scripts/gendoc.lua`          |
| Generated help      | `nvim --headless -u scripts/minimal_init.lua -l scripts/genhelp.lua`         |

The typecheck needs `VIMRUNTIME` exported, so that `$VIMRUNTIME/lua` in
`.luarc.json`'s `workspace.library` resolves. Neither the hook nor CI trusts its
exit code, which some releases leave at zero with problems found; both read its
`no problems found` summary line instead.

Query formatting is owned by the tool, not by you: drop the `--check` and it
rewrites `queries/`, which is what `.husky/pre-commit` does. One write pass does
not converge, so the hook runs it twice and then asserts with `--check`. Note it
indents at two spaces and offers no way to change that, which is why
`.editorconfig` has a `[*.scm]` block.

The last two rows regenerate rather than check. Nothing under `docs/` or `doc/`
is written by hand; CI regenerates each and then fails if
`git status --porcelain` reports anything against it, so a stale page cannot
survive a pull request. Run the docs one after changing any annotation under
`lua/`, `lsp/` or `init.lua`, and the help one after changing a mapping, a user
command, an option, an autocommand or a plugin spec's `keys`.

To run part of the suite, set `MINITEST_PATTERN` to a Lua pattern matching the
case descriptions you want:

```sh
MINITEST_PATTERN='util%.header' \
    nvim --headless -u scripts/minimal_init.lua -l scripts/minitest.lua
```

Two sweeps exist that no gate runs, because they are for reading rather than
satisfying: `scripts/typecheck_sensitive.lua` repeats the typecheck at `Hint`,
ie. everything the gate ignores.

## Features worth knowing about

**WIP snapshots.** `lua/util/wip.lua` commits the in-memory text of a tracked
buffer onto `refs/wip/<branch>` every couple of seconds, using git plumbing
only, so unsaved work survives a crash without any of it becoming visible
repository state. HEAD, the index and the working tree are never written, and
`refs/wip/*` stays out of `git branch`, `git log` and `git push`. Recovery is
plain git:

```sh
git log refs/wip/main
git show refs/wip/main:lua/util/wip.lua
git restore --source=refs/wip/main -- lua/util/wip.lua
```

`XXWip` takes `toggle`, `enable`, `disable` and `snapshot`, plus a bang-only
`drop`. Nothing prunes the ref, so it grows until dropped.

**Repository-aware statusline.** The leading `%f` of Neovim's default statusline
is replaced with the same notation this repository writes into its file headers,
ie. `~chewygumxx/nvim-config.git:main:/lua/util/statusline.lua`, coloured a part
at a time. A path's tail alone is ambiguous across checkouts and worktrees of
one project; the slug and branch disambiguate them. Nothing in the render path
calls git.

**Markdown list continuation.** Neovim will not continue a Markdown list, and
not by omission: its own ftplugin removes the `formatoptions` flags that would.
`lua/util/markdown_list.lua` computes the next `- `, `- [ ] `, `2. ` or `> `
prefix instead, on `o`, `O` and `<M-CR>`, and never on `<CR>`, which belongs to
completion.

**Its own `:help`.** `doc/nvim-config.txt` is generated from the configuration
rather than written beside it, so `:help nvim-config` answers with the mappings,
commands, options and autocommands actually registered. `stdpath("config")` is
always first on `runtimepath`, which is what makes a config repository able to
host help at all; `doc/tags` is tracked because lazy.nvim runs `helptags` for
plugins and never for the configuration directory. Nothing is parsed out of the
source: each module's `setup()` is called under a stub of the API it writes
through.

**File headers.** Nearly every tracked file opens with a modeline, an SPDX
identifier and a boxed comment naming the repository and the file's path within
it. `XXInsertHeader` writes one, a GitHub Action corrects drift on every push,
and Markdown files carry the same three parts inside a `__cgxx: |` block at the
head of their YAML frontmatter.

## Contributing

Commits are [Conventional Commits](https://www.conventionalcommits.org),
enforced by commitlint through husky. Scopes come from a fixed list in
`.commitlintrc.mts` (`hl`, `opt`, `ft`, `key`, `ucmd`, `acmd`, `lsp`, `spec`,
`util`, `asset`, `claude`), and the whole `type(scope): Subject` header is
capped at 50 characters, so subjects stay short. `npm run commit` walks through
it interactively.

`.claude/CLAUDE.md` is the long-form reference: what each directory is for,
which decisions are load-bearing and why, and what a given change is likely to
break. Read it before changing anything structural. Several directories carry
their own `CLAUDE.md` with conventions specific to them, and `.claude/skills/`
holds the per-subsystem reasoning that only matters when you are in that
subsystem.

`.claude/settings.json` wires five hooks that run if you work here through
Claude Code, and they are worth knowing about before one surprises you: writes
into `doc/` and `docs/` are refused because both are regenerated wholesale, a
commit is refused while any gate binary is missing from `PATH`, Lua is formatted
and linted at write time, a reminder fires when a change makes the generated
`:help` stale, and whole-file reads of the wordlists and the compiled spell file
are refused in favour of `head` or `wc`. None of them affects a normal editor
session.

## Licence

GPL-3.0-only. See [LICENSE](LICENSE).
