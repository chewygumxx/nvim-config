---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/skills/generated-output/SKILL.md
  #
  #

ctime: 2026-09-27
title: Generated output
name: generated-output
description: >-
  Regenerate or reason about this repository's two generated trees, doc/ and
  docs/. Use when touching scripts/genhelp.lua, scripts/gendoc.lua or
  lua/util/vimdoc.lua, when the Help or Docs CI job fails, when a mapping, user
  command, option, autocommand or a spec's keys has changed, or when anything
  wants to write into doc/ or docs/ by hand.
tags:
  - llm
  - claude
---

# Generated output

Two trees here are generated, tracked, and never edited by hand. `doc/` is this
repository's own `:help`; `docs/` is the browsable LuaCATS reference. They are
genuinely confusable and the pair is not a rename waiting to happen: `doc/` is
the only name Neovim's `runtimepath` scan accepts.

## Never hand-edit either

Both generators `delete(dir, "rf")` and recreate, so a file written into either
by hand is removed on the next run without a word. That was confirmed by
planting a file in each and running them; neither said anything. It rules out a
`CLAUDE.md`, a `README`, a `.gitkeep` or a banner file in either, which is why
the do-not-edit warning is rendered _into_ the help text and enforced by
`.claude/hooks/block-generated.sh` rather than left beside the output.

It is also stated in `.claude/rules/doc.md` and `.claude/rules/docs.md`, which
sit outside both trees and so survive the generator. Each is scoped by a `paths`
glob and loads on a read of a file in its own tree, which is the half the hook
cannot reach: the hook refuses a write and says nothing until one is attempted.

`doc/` is the more dangerous of the two through Claude Code, not the less. The
`.md` reflow hook does not touch it, since it holds `.txt`, so a hand edit there
survives the write and is destroyed by the next generator run instead of being
visibly mangled.

## Regenerating

Run both through Neovim so the child inherits `$VIMRUNTIME`, which
`.luarc.json`'s `workspace.library` needs. From a bare shell the analysis
silently resolves against nothing.

```sh
nvim --headless -u scripts/minimal_init.lua -l scripts/genhelp.lua
nvim --headless -u scripts/minimal_init.lua -l scripts/gendoc.lua
```

Then verify with `git status --porcelain -- doc/ docs/` and **not** with
`git diff`. Three things can make a tree stale and a plain diff sees only one: a
changed page it does catch, a _new_ page which is untracked and so invisible to
it, and a page the generator no longer produces, which `git add -A` would stage
away before the diff ran. `status` reports all three and touches no index. Each
case was checked in turn rather than reasoned about, which is how the second and
third were found. Both CI jobs ask the same question the same way.

Run `genhelp.lua` after changing a mapping, a user command, an option, an
autocommand or a spec's `keys`. `.claude/hooks/stale-help.sh` says so at write
time.

Neither generator belongs in `.husky/pre-commit`, which runs formatters, the
LuaLS check and the suite. Both are gated CI-only, by the `Help` and `Docs` jobs
in `.github/workflows/lint-config.yaml`. `Help` installs only Neovim, since
nothing third-party is involved; `Docs` installs the `emmylua_doc_cli` pin
beside it.

## `doc/` and the vimdoc renderer

`doc/nvim-config.txt` is generated from the configuration rather than written
beside it. A config repository can host help at all because `stdpath("config")`
is always first on `runtimepath`; the only plumbing that needs is `doc/tags`,
which is tracked because lazy.nvim runs `helptags` for the plugins it manages
and never for the configuration directory. The `Help` job runs `helptags`
against a staging copy, so a file it rejects never reaches `doc/`.

The split is the point. `lua/util/vimdoc.lua` is pure rendering and touches
neither the session nor the filesystem, which is what lets
`tests/test_util_vimdoc.lua` assert column arithmetic without running any
`setup()`; `scripts/genhelp.lua` harvests and writes. `M.width` is 78 rather
than `.editorconfig`'s 80 because that is what a help window shows, and `M.fit`
exists because `util.text.wrap_comment` breaks on whitespace alone: 'statusline'
is one token of nearly two hundred characters and was emitted whole until it was
added. Its first version tested whether the _remainder_ fit rather than the
remainder plus its continuation gutter, which let a 99-column line through; that
case is now a named test.

### Nothing is parsed out of the source

`lua/keymap/init.lua` and `lua/usercmd/init.lua` set their mappings and commands
imperatively inside `setup()`, with `lhs` and `desc` as defaulted function
parameters, so there is no table to read, and reading the `---@param` prose
instead would make a second source of truth out of a comment. Each `setup()` is
called under a stub of the API it writes through, which is exactly what
`tests/test_keymap.lua`, `test_option.lua` and `test_autocmd.lua` already do to
assert the whole set a module registers; those discard the descriptions, so this
is the same pattern rather than a shared function.

The stubs go in before the first `require`, since `lua/autocmd.lua` creates its
augroup at module load rather than in `setup()` and `require`'s cache will not
run the file twice. `keymap.gx` defers into `vim.schedule`, so the capture waits
for it with the stub still installed, and a run where it never arrives is fatal.

Plugin mappings are the opposite case and are read statically, the way
`tests/test_spec.lua` reads them, because a spec's `keys` is plain data. They
are filtered against `lua/plugin.lua`'s `elide` and `condemn` lists _and_
against a spec's own `cond`/`enabled`, since both switch a plugin off and only
the second is visible from the spec file; a help page advertising `<leader>fu`
for an elided telescope would be worse than one that omits it.

### The header

Help files have no comment syntax, so `# %s` is assumed rather than derived,
which is the same move `util.header.frontmatter` makes inside frontmatter. The
modeline is the expanded `vim:set textwidth=78 tabstop=8 filetype=help:` rather
than `runtime/doc`'s terse form, which is what the rest of this repository
writes anyway. `noexpandtab` is deliberately dropped, since everything generated
here is space-indented and setting it would describe the file wrongly.

`util.header.plain` was extracted from `M.insert` to render that box without a
buffer to read a 'commentstring' or filetype from, and `util.modeline.base` grew
a `prepend` clause because its option order is fixed and `textwidth` has to
precede `filetype`. `sync-header-metadata` needs no exclusion for the file: it
finds its two markers by end-anchored regex and preserves whatever precedes
them, so the comment syntax is never its business. `doc/tags` does need one, in
`.gitattributes`, being TAB-separated records with nowhere to put a comment.

## `docs/` and the LuaCATS reference

`scripts/gendoc.lua` renders it from the LuaCATS annotations under `lua/`,
`lsp/` and `init.lua` via `emmylua_doc_cli`. `lua/spec/` is excluded, since
getting on for half the Lua files here are declarative `LazySpec` tables with no
callable API and would crowd out everything a reader can actually call.

Three decisions in that script are load-bearing and each has its reason inline.
The tree is built in a staging directory and only installed once proved
non-empty, so a failed run leaves the committed docs alone rather than
committing an empty one. It is replaced wholesale rather than written over,
because a write-only generator leaves the page for a deleted module behind with
`git diff` reporting no change and the gate staying green. And the `mkdocs.yml`
the generator emits beside the Markdown is deliberately discarded, since it
carries trailing whitespace and CI runs prettier over every `*.yml`, which is
the same two-tools-one-file standoff `.prettierignore` settles for
`lazy-lock.json`.

## What this replaced

which-key's popup used to be the only place a leader-prefix collision became
visible. The keymaps and plugin-mappings sections of `doc/nvim-config.txt` are
now a second place, and unlike the popup they are visible to a headless process
and to `git diff`. The popup is still the only place the grouping and its
wording can be judged.
