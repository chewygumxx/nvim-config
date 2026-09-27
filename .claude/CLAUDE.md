---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/CLAUDE.md
  #
  #

ctime: 2026-09-26
title: CLAUDE.md
description: >-
  The long-form reference for this configuration: why each decision is the way
  it is, and what a given change is likely to break.
tags:
  - llm
  - claude
---

# CLAUDE.md

Absolutely no em dashes are to be employed within this repository.

Ensure any printed conversation output line length is limited to 80 characters
except where it may be unfeasable to do so eg. URL.

## What this repository is

`chewygumxx/nvim-config`: a standalone Neovim configuration, plugin-managed by
[lazy.nvim](https://lazy.folke.io). It is not part of the dotfiles repo; it has
its own git history, its own commitlint/CI setup, and no chezmoi involvement.

Two tracked documents, with different jobs. `README.md` orients someone arriving
at the repository: requirements, `mise install`, the directory layout, the gate
commands in a table, and the handful of features worth knowing about. **This**
file is the long-form reference: why each decision is the way it is, and what a
given change is likely to break. Anything that is a fact about the code belongs
in the README or a doc comment; anything that is a reason belongs here.

A `plan.md` was tracked for one tranche of work and retired once its phases
landed, which is the expectation for any future one: a plan reasons from how
things ought to work and the implementation finds out how they do, so a reason
worth keeping belongs here rather than in the plan that produced it.

Several directories additionally carry their own `CLAUDE.md`, named rather than
counted here because a count is the half that rots: `.github/`, `lua/spec/`,
`lua/filetype/`, `tests/`, `lua/util/`, `lsp/` and `queries/`. Each is
deliberately short and holds only what is easy to violate from outside the
directory and not derivable from reading it, and each is rules and reasons
rather than an inventory, for the same reason this file is: a localised file
that restates a fact creates a second copy of it to drift. **None of them is
reached by any gate**, since no workflow or hook globs `*.md`, so correctness
there is entirely a matter of care at write time.

`docs/` and `doc/` are the two directories most in need of a "do not edit this
by hand" note and the two that cannot hold one, since `scripts/gendoc.lua` and
`scripts/genhelp.lua` both `delete(dir, "rf")` and recreate. Confirmed by probe:
a file planted in each vanished and neither generator said a word, which rules
out a `CLAUDE.md`, a `README` or a `.gitkeep` there. Working through Claude Code
adds one wrinkle. A hook reflows `.md` files on every write, which is harmless
for prose and would corrupt `docs/`, while `doc/` is exempt by holding `.txt`,
making a hand-edit there survive the write and die at the next generator run.
Regenerate both; never type into either.

`.claude/` holds more than this file. `skills/` carries the per-subsystem
references that load only when that subsystem is touched, which is why this file
is a fraction of the length it once was. `commands/` holds `/gate-battery`,
`/regen` and `/fresh`, `agents/gate-runner.md` runs the gate battery without its
output reaching the caller, and `hooks/` makes five of the rules here mechanical
rather than advisory. **Source `hooks/lib/tools.sh` before running any gate by
hand**, since mise is not activated in a Claude Code shell and half the gate
binaries otherwise resolve to something other than the pin.

The **`claude-assets` skill** holds the rest, and is what to read before adding
or changing anything under `.claude/`: how each kind of asset loads, the one
namespace a command and a skill share, the frontmatter rules
`tests/test_claude_assets.lua` enforces, and why a `PreToolUse` hook is
preferred to a `permissions.deny` rule.

## Commands

There is no build step; everything is a check, and the **`gates` skill** holds
all of it: what each tool is for and where its config lives, `mise.toml` as the
single source of every pin, the sweeps that are deliberately not gates, what
`.husky/pre-commit` actually runs and why it skips a missing tool in silence,
and the rules that make a result believable. `/gate-battery` runs the battery in
the caller's own context with the output; the `gate-runner` subagent runs the
same sequence and reports only failures. The **`generated-output` skill** holds
the two generators, which are deliberately neither gates nor part of
`.husky/pre-commit`; `/regen` runs both and verifies them.

`.husky/commit-msg` enforces commitlint, and unlike the dotfiles repo's
free-form scopes this one's `.commitlintrc.mts` fixes `scope.enum` at `hl`,
`opt`, `ft`, `key`, `ucmd`, `acmd`, `lsp`, `spec`, `util`, `asset` and `claude`.
Scope is optional and several can be joined with `/`, but nothing outside that
list is accepted, **including a type name**: `docs(ci)` is rejected, since `ci`
is a type rather than a scope. `header-max-length` caps the whole
`type(scope): Subject` header at 50 characters, so keep subjects short.

## Architecture

### Entry point and load order

`init.lua` calls `require(modpath).setup()` directly for each top-level module,
with no `require_guard`/`setup_guard` wrapper. One existed and was deliberately
removed: now that this configuration is its own repository rather than a
subdirectory of the dotfiles repo, a misconfigured module is cheaply fixed by
reverting the checkout, so guarding every call against a broken sibling stopped
earning its complexity. The load order is deliberate and documented inline
there, `highlight` last so it outranks whatever the colourscheme and Tree-sitter
set. Note the sixth call is `require("plugin").setup()` and not `util.lazy`
directly, so the comments naming `util.lazy` describe the dependency rather than
the call.

There is no `cgxx` settings-as-plugin indirection layer and no
`lua/plugin_manager.lua`, whatever an earlier revision of this file claimed.
Machine- and environment-specific choices, ie. colourscheme, fuzzy finder and
the Herdr and Termux checks, are made at the point of use.

### Plugin bootstrap (`lua/util/lazy.lua`) and specs (`lua/spec/`)

`lua/util/lazy.lua` is this config's lazy.nvim bootstrap, and `lua/plugin.lua`
is what decides the spec list and hands it to `util.lazy.setup`. **The `specs`
skill holds the rest**: the `elide`/`condemn` distinction and the single place
it survives lazy.nvim's merge, why `lazy-lock.json` is tracked and what its
retention behaviour means, the leader prefixes and the collision that
established them, the checklist for adding a spec, and the `vim.tbl_deep_extend`
merge trap that `lua/spec/hardtime.nvim.lua` demonstrates.

Two things bear on reading any spec at all, so they are here rather than only
there. Enabling and disabling is centralised in `lua/plugin.lua` and not written
onto each spec, but a spec may still carry a condition of its own where that
condition is about the plugin rather than about our use of it, and two do:
**`lua/plugin.lua` tells you what is disabled and not always why**. And
`lazy-lock.json` is **tracked**, one file serving Arch, Termux and Herdr despite
their differing plugin sets, because lazy.nvim keeps the entries of plugins it
is not currently managing; **an entry records a pin to return to, not that the
plugin is in use**.

### LSP (`lsp/`, `lua/spec/nvim-lspconfig.lua`, `lua/util/lsp.lua`)

This configuration uses Neovim's **native** `vim.lsp.config` and
`vim.lsp.enable` mechanism, not `nvim-lspconfig`'s old `setup{}` API, with one
table per server in `lsp/` at the repository root and everything shared in
`lua/util/lsp.lua`. `mason-lspconfig.nvim` installs and enables them, and is
condemned outright under Termux, which is why `mise.toml` pins the same servers.
`lsp/CLAUDE.md` holds what belongs in a per-server file and what does not,
including why an empty one is a legitimate configuration.

### Filetype system (`lua/filetype/`)

`lua/filetype/init.lua` keeps detection and dispatch in separate tables:
`M.filetypes` holds the patterns Neovim does not recognise out of the box and is
registered through `vim.filetype.add()`, while `M.modmap` routes an
already-detected filetype to a module beside it off a `FileType` autocmd. **The
dispatcher runs exactly one module per filetype**, which is the part that
surprises: a compound filetype inherits nothing from the plain one, so
`lua/filetype/nex_note.lua` aliases `markdown.setup` outright and
`lua/filetype/claude.lua` calls it before its own work. `lua/filetype/CLAUDE.md`
holds the module contract, what that one-module rule has already cost, and the
`gitcommit` decisions.

### Four features that carry their own skill

Each of these is unusual enough that the obvious reading of the code is the
wrong one, and each has a skill holding the decisions and the traps. What is
here is only enough to know the feature exists and is deliberate.

- **Markdown list continuation** (`lua/util/markdown_list.lua`). Neovim will not
  continue a Markdown list, and not by omission: its own ftplugin removes the
  `formatoptions` flags that would. Bound to `o`, `O` and `<M-CR>`, never to
  `<CR>`, which belongs to completion. See the **`markdown-continuation`
  skill**.
- **The repository-notation statusline** (`lua/util/statusline.lua`), installed
  by `option.view.setup()` over the _default_ 'statusline' so that everything
  else Neovim puts there survives. Three decisions there are load-bearing and
  each has a test that fails if it is undone. See the **`statusline` skill**.
- **Its own `:help`** (`doc/`, `lua/util/vimdoc.lua`, `scripts/genhelp.lua`),
  generated from the configuration rather than written beside it. A
  configuration repository can host help at all because `stdpath("config")` is
  first on `runtimepath`, and `doc/tags` is tracked because lazy.nvim runs
  `helptags` for plugins and never for the configuration directory.
  `lua/util/vimdoc.lua` is pure rendering and `scripts/genhelp.lua` does all the
  harvesting and writing, which is what makes the renderer testable. See the
  **`generated-output` skill**.
- **WIP snapshots** (`lua/util/wip.lua`), committing the in-memory text of a
  tracked buffer onto `refs/wip/<branch>` with git plumbing only, so unsaved
  work survives a crash without becoming visible repository state. HEAD, the
  real index and the working tree are never written. See the **`wip` skill**.

### Other directories

- `lua/util/`: the shared helpers, which are libraries first rather than modules
  with a `setup` contract. `lua/util/CLAUDE.md` holds what a module here owes,
  including the annotation habits `luafmt` will otherwise silently undo.
- `lua/usercmd/`: user commands are defined centrally in `lua/usercmd/init.lua`,
  each delegating to a feature module (`lua/usercmd/*.lua` or `lua/util/*.lua`)
  rather than inlining logic.
- `tests/`: the mini.test suite, one `test_<module>.lua` per module under test,
  plus several files that police a whole directory instead. Everything about
  writing one is in `tests/CLAUDE.md`, and it all follows from the suite sharing
  a single Neovim process. Two of those registry files reach back into this one:
  `test_coverage.lua` requires every module under `lua/` to have a test or a
  stated exemption, and `test_claude_assets.lua` requires every rooted path
  named anywhere under `.claude/` to exist.
- `scripts/`: the headless entry points, described by the `gates` skill except
  for `scripts/gendoc.lua` and `scripts/genhelp.lua`, which belong to
  `generated-output`. **None of them may reach the network**, which is why
  `scripts/lazy_merge.lua` asserts lazy.nvim is already installed rather than
  letting `util.lazy.setup` clone it, and forces `install.missing = false` with
  `checker` and `rocks` off.
- `docs/` and `doc/`: the browsable LuaCATS reference and this repository's own
  `:help`. Both generated, tracked and never edited by hand, gated by the `Docs`
  and `Help` jobs, and both refused to a write by
  `.claude/hooks/block-generated.sh`.
- `queries/`: Tree-sitter queries picked up by Neovim's runtimepath convention,
  and each one **replaces** the runtime query for its language rather than
  extending it, since none carries an `; extends` comment. Layout here is owned
  by `ts_query_ls format`, which is the reason `.editorconfig` has a `[*.scm]`
  block at two spaces against the repository's usual four. `queries/CLAUDE.md`
  holds the rest.
- `snippets/`: a friendly-snippets-style manifest plus per-language JSON.
  LuaSnip is elided, so the spec loads and the plugin does not.
- `types/`: `---@meta` stubs for what LuaLS cannot see on its own, never
  required or executed, which is why `.husky/pre-commit` holds `selene` back
  from here: their intentional global declarations would otherwise read as real
  bugs. **Do not delete a stub because `workspace.library` appears to make it
  redundant.**
- `.repo-metadata.jsonc`: the GitHub repository's own description, topics and
  licence, applied by the `sync-repo-metadata` Action whenever it changes, so
  those settings are edited here rather than in the web interface.
- `.github/`: the workflows, the three composite actions they share, and
  `.github/scripts/tool_version.py`, which is how a job reads a pin from
  `mise.toml` rather than restating it. `.github/CLAUDE.md` holds the rules,
  including the two ways a job here can go green over a gate that never ran.

## Conventions

- **File headers**: nearly every tracked file opens with an editor modeline, an
  `SPDX-License-Identifier: GPL-3.0-only` line and a boxed comment giving the
  repository slug and the file's repo-relative path (eg.
  `::: :/lua/util/lsp.lua`), in that file's line-comment syntax. Follow a
  sibling of the same type rather than inventing one; `XXInsertHeader` generates
  one, and the `sync-header-metadata` Action corrects drift on every push to
  `main`.
- **Markdown headers** are those same three parts wearing YAML: a `__cgxx: |`
  block inside the frontmatter, each line indented two spaces and commented `#`,
  then `ctime:`, `title:`, `description:` and `tags:`, then the `#` heading.
  `util.header.frontmatter` renders the whole document head and is the only
  description of that shape, so copy a sibling or call it rather than assembling
  one by hand. It is gated on `filetype == "markdown"` exactly, which is why
  `markdown.claude` and `markdown.nex-note` do not get it automatically.
- **Indentation**: owned by `.editorconfig`, 4 spaces except 2 for `*.md` and
  `*.scm`, and Lua additionally by `luafmt`'s `max_line_width = 80`. The `*.scm`
  entry follows `ts_query_ls format` rather than the other way round.
- **Lua annotations vs. `luafmt`**: two habits exist because the formatter will
  otherwise silently undo the annotation, and `lua/util/CLAUDE.md` states both
  with their reasons. They apply to Lua anywhere in the repository, not only
  under `lua/util/`.
- **Commit messages**: Conventional Commits, enforced by commitlint and husky,
  with scope from the fixed list above and `claude` for anything under
  `.claude/`. Do not invent ad hoc scopes like the dotfiles repo's
  `feat(nvim): ...` style.
- **No AI co-author trailers**: do not add a `Co-Authored-By: Claude ...` (or
  similar) trailer unless explicitly asked to, on that specific commit.

## Behaviours no gate covers

Four things here are asserted only as far as a headless process can reach, so a
regression in them is silent and has to be looked at. All four were confirmed by
hand in a live Neovim on 2026-09-27, which is what makes them a baseline rather
than an open question; re-check the relevant one after touching it.

- **The statusline colours, and truncation from the left.** The tests assert
  which highlight group covers which byte range, not whether the palette is
  legible against the colourscheme, and `%<` only shows in a narrow window.
- **The `gitcommit` header overflow.** The tests check that `colorcolumn=51,73`
  is declared, not that it lands where git's limits are.
- **`<leader>.` returning the same scratch buffer after a restart.** Persistence
  across processes is exactly what a single headless run cannot observe.
- **which-key's group labels.** A prefix collision is now visible to a headless
  process, since `doc/nvim-config.txt` lists the same ground and CI diffs it,
  but the popup remains the only place the grouping and its wording can be
  judged.
