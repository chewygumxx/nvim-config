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
landed, which is the expectation for any future one: a working plan is a
scaffold, and a reason worth keeping belongs in this file rather than in the
plan that produced it. It is worth knowing that a plan of that kind reasons from
how things ought to work and the implementation finds out how they do, so its
text will disagree with the tree in places; where that disagreement mattered it
was moved here.

Several directories additionally carry their own `CLAUDE.md`, and it is named
rather than counted here because the count is the half that rots:
`.github/workflows/`, `lua/spec/`, `lua/filetype/`, `tests/`, `lua/util/`,
`lsp/` and `queries/`. Each is deliberately short and holds only what is easy to
violate from outside the directory and not derivable from reading it, ie. the
`elide`/`condemn` distinction that is invisible after lazy.nvim's merge, the
one-module-per-filetype rule, the one-shared-process discipline the test suite
depends on, the two annotation habits `luafmt` will otherwise undo, the
`ensure_installed` parity assertion, and the absence of `; extends`. They are
rules and reasons rather than inventories, for the same reason this file is: a
localised file that restates a fact creates a second copy of it to drift. None
of them is reached by any gate, since no workflow or hook globs `*.md`, so
correctness there is entirely a matter of care at write time.

The two directories most in need of a "do not edit this by hand" note are the
two that cannot hold one. `scripts/gendoc.lua` and `scripts/genhelp.lua` both
`delete(dir, "rf")` and recreate, for the reason each states inline, so any file
added to `docs/` or `doc/` by hand is removed on the next run without a word.
That was confirmed by probe rather than reasoned about: a file planted in each
vanished and neither generator said anything. It rules out a `CLAUDE.md`, a
`README`, a `.gitkeep` or a banner file in either, and it is the reason the rule
below lives here instead.

One hazard specific to working through Claude Code: a hook reflows `.md` files
on every Write or Edit. That is harmless for prose but would corrupt generated
output, so never edit anything under `docs/` by hand; regenerate it. `doc/` is
exempt from the hook, holding `.txt` rather than `.md`, which makes hand-editing
it _easier_ rather than safer: the edit survives the write and is destroyed by
the next generator run.

`.claude/` holds more than this file. `skills/` carries six per-subsystem
references that load only when that subsystem is touched, which is why this file
is roughly half the length it once was: the reasons did not go away, they
stopped being loaded into every session regardless of relevance. `commands/`
holds `/gate-battery`, `/regen` and `/fresh`; `agents/gate-runner.md` runs the
gate battery without its output reaching the caller, though note a newly added
agent is not selectable as a `subagent_type` until the session restarts, so the
one that creates it cannot use it; and `hooks/` makes five of the rules here
mechanical rather than advisory, refusing a write into a generated tree,
refusing a commit while a gate binary is absent, refusing a whole-file read of
the wordlists and the compiled spell file, linting Lua at write time, and
reporting that the generated help has gone stale.

A command and a skill share one name namespace, which is why the first of those
is `/gate-battery` and not the `/gates` it would otherwise read as. Claude Code
lists a command by its filename stem beside a skill by its directory name, so a
collision leaves exactly one of the pair reachable and says nothing at all about
the other. `/gates` lost to the `gates` skill from the day it was written, and
sat unreachable and unread for as long as this file went on describing it as the
way to run the battery. That was established by probe rather than reasoned
about: only one `gates` entry ever reached a session listing and it carried the
skill's description, invoking the name returned the skill's body, and renaming
the command made both appear at once within the same session.
`tests/test_claude_assets.lua` now asserts the two sets of names are disjoint,
which nothing did before: it had always checked skills, commands and agents as
three independent groups, so a shadowed command passed every case. Agents are a
separate namespace, chosen by `subagent_type` rather than by slash, so
`gate-runner` can sit beside both without shadowing either.

That fifth one is a hook rather than a `permissions.deny` rule for a reason
worth knowing before reaching for `deny` again. A `Read(...)` rule is not scoped
to the Read tool: Claude Code recognises file-naming commands inside Bash and
applies the rule to those too, so `Read(/words.txt)` also denies
`head -3 words.txt`, `wc -l words.txt` and `ls -la words.txt`, and blocks Edit
and Write on the path besides. That was established by adding the rule and
running each command rather than reasoned about. A `PreToolUse` hook blocks just
as hard, since exit 2 stops a call before permission rules are evaluated, but
leaves Bash alone and can name the cheap route instead of merely refusing.

`hooks/lib/tools.sh` is the one to know about first. mise is not activated in a
Claude Code shell, so without its `PATH` prefix `ts_query_ls` is absent entirely
and `.husky/pre-commit` skips the whole tree-sitter query gate in silence, while
`luafmt` and the two `emmylua` binaries resolve to a cargo build rather than to
the pin. Source it before running any gate by hand. Do not reach for `mise exec`
instead: `mise.toml` pins the editor toolchain beside the gates, so it begins
installing 22 tools before it answers.

A skill's frontmatter `description` is the only thing deciding whether it loads,
and each is written as a folded block scalar (`description: >-`) rather than a
bare `description:`. The reflow hook rewraps a long description either way, but
a bare key yields a plain multiline scalar, which is valid YAML that **cannot
contain `": "`**; `>-` folds to the same single line and tolerates a colon
anywhere. That was established by probe rather than reasoned about. `/fresh` is
the end-of-session check that all of this is still true of the tree.

## Commands

There is no build step; everything is a check. The **`gates` skill** holds all
of it: what each tool is for and where its config lives, `mise.toml` as the
single source of every pin, how to reach that toolchain from a shell where mise
is not active, the two sweeps that are deliberately not gates, what
`.husky/pre-commit` actually runs and why it skips a missing tool in silence,
and the two rules that make a `lua-language-server` result believable.
`/gate-battery` runs the battery in the caller's own context, with the output;
the `gate-runner` subagent runs the same sequence and reports only failures,
keeping the thousands of passing lines out.

The **`generated-output` skill** holds the two generators, `scripts/genhelp.lua`
and `scripts/gendoc.lua`, which are deliberately neither gates nor part of
`.husky/pre-commit`. `/regen` runs both and verifies them.

`.husky/commit-msg` enforces commitlint.

Unlike the dotfiles repo's free-form scopes, this repo's `.commitlintrc.mts`
defines a fixed `scope.enum` (`hl`, `opt`, `ft`, `key`, `ucmd`, `acmd`, `lsp`,
`spec`, `util`, `asset`, `claude`, each with a `fullName`/`description` used to
label `npm run commit`'s prompt) alongside its `type.enum` (`feat`, `fix`,
`tweak`, `chore`, `style`, `docs`, `ci`, `refactor`, `perf`, `build`, `test`,
`revert`); scope is optional, and per `scope-delimiter-style` multiple scopes
can be joined with `/`. `header-max-length` caps the whole
`type(scope): Subject` header at 50 characters, so keep subjects short.

## Architecture

### Entry point and load order

`init.lua` calls `require(modpath).setup()` directly for each top-level module;
there is no `require_guard`/`setup_guard` safety wrapper. Earlier revisions had
one, but it was deliberately removed (`refactor: Remove global variables`): now
that this config is its own repository rather than a nested subdirectory of the
dotfiles repo, a misconfigured module is cheaply fixed by reverting the local
checkout, so guarding every `setup()` call against a broken sibling module
stopped being worth the complexity.

`init.lua` then loads top-level modules in a deliberate order, documented
inline: `option`, `keymap`, `filetype` (after option/keymap, so its
`FileType`-triggered overrides win), `autocmd`, `usercmd`, `plugin` (after
keymap/filetype/autocmd, since lazy-loaded plugin specs key off
`vim.g.mapleader`, filetype autocmds, and augroups defined earlier), then
`highlight` last, so it overwrites whatever the colorscheme and treesitter
plugins set. Note the sixth call is `require("plugin").setup()` and not
`util.lazy` directly: `lua/plugin.lua` is what decides the spec list and hands
it to `util.lazy.setup`, so the comments inside `init.lua` naming `util.lazy`
describe the dependency rather than the call.

There is no `cgxx` settings-as-plugin indirection layer and no
`lua/plugin_manager.lua`; earlier revisions of this file described one, but it
has since been removed. Machine- and environment-specific choices (colorscheme,
fuzzy finder, Herdr/Termux checks) are now made directly at the point of use in
the relevant module or plugin spec, described below.

### Plugin bootstrap (`lua/util/lazy.lua`) and specs (`lua/spec/`)

`lua/util/lazy.lua` is this config's lazy.nvim bootstrap, and `lua/plugin.lua`
is what decides the spec list and hands it to `util.lazy.setup`. **The `specs`
skill holds the rest**: the `elide`/`condemn` distinction and the single place
it survives lazy.nvim's merge, why `lazy-lock.json` is tracked and what its
retention behaviour means, the leader prefixes and the collision that
established them, the checklist for adding a spec, and the `vim.tbl_deep_extend`
merge trap that `lua/spec/hardtime.nvim.lua` demonstrates.

Two things are worth having here rather than only there, because they bear on
reading any spec at all. Enabling and disabling is centralised in
`lua/plugin.lua`, not written onto each spec, so that is the first place to
look. But a spec may still carry its own condition where that condition is
specific to the plugin rather than a policy about it, and two currently do on
top of being listed: **reading only `lua/plugin.lua` tells you what is disabled,
but not always why**.

`lazy-lock.json` is **tracked**, which is the one decision here whose
consequences reach outside this section. One file serves Arch, Termux and Herdr
despite their differing plugin sets, because lazy.nvim's writer keeps the
entries of plugins it is not currently managing. **An entry therefore records a
pin to return to, not that the plugin is in use**, and the lock cannot be used
to tell an elided plugin from a condemned one. `.prettierignore` excludes it,
since lazy.nvim writes one line per plugin and prettier expands each across
four.

Plugin specs load through lazy.nvim's own `{ import = "spec" }` mechanism,
walking `lua/spec/*.lua` directly; there is no repo-specific spec resolver. Each
file is a self-contained `LazySpec` for one plugin, matching the plugin's own
repo name (e.g. `lua/spec/fzf-lua.lua` -> `ibhagwan/fzf-lua`).
`M.defaults.spec = "spec"` is the bare form of that, and `lua/plugin.lua`
overrides it with `M.import()`.

Colourscheme selection is inlined rather than indirected:
`lua/spec/starry.lua`'s `config()` calls `vim.cmd("colorscheme starry")`
directly. `lua/spec/fzf-lua.lua` is the fuzzy finder;
`lua/spec/telescope.nvim.lua` is still present but elided, so it is a spec kept
for reference rather than a fallback that loads.

### LSP (`lsp/`, `lua/spec/nvim-lspconfig.lua`, `lua/util/lsp.lua`)

This config uses Neovim's **native** `vim.lsp.config`/`vim.lsp.enable` mechanism
(0.11+), not `nvim-lspconfig`'s old `setup{}` API. Per-server config tables live
in `/lsp/<name>.lua` at the repo root: Neovim's built-in runtimepath convention,
auto-discovered by `vim.lsp.enable()`. `mason-lspconfig.nvim`
(`lua/spec/mason-lspconfig.nvim.lua`) installs everything in `ensure_installed`
and calls `vim.lsp.enable()` for all of them via `automatic_enable = true`. On
Termux the whole mason trio is disabled, since it lacks mason's toolchain, but
that gate lives in `lua/plugin.lua`'s `condemn` list rather than on the specs
themselves, and `mise.toml` is where those same servers come from instead.
`lua/util/lsp.lua` centralizes what would otherwise be duplicated per-server:
capabilities (merges blink.cmp's completion capabilities over Neovim's
defaults), `vim.diagnostic.config()`, and the buffer-local keymaps wired up on
every `LspAttach` (`gd`, `gr`, `K`, `<leader>ca`, etc.), so a per-server
`lsp/*.lua` only needs to add what's actually server-specific (`root_markers`,
extra `capabilities`, an `on_attach` for highlight groups).

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

### Markdown list continuation (`lua/util/markdown_list.lua`)

Neovim will not continue a Markdown list, and not by omission:
`$VIMRUNTIME/ftplugin/markdown.vim` removes the two `formatoptions` flags that
would, and `comments` could not express the forms this needs anyway, so the
continuation is computed in Lua. It is bound to `o`/`O` and `<M-CR>` and
deliberately **not** to `<CR>`, which `lua/spec/blink.cmp.lua` needs for
completion.

The **`markdown-continuation` skill** has the rest, including why adding to
`lua/filetype/markdown.lua`'s `setup` is what reaches all three compound
Markdown filetypes.

### Statusline (`lua/util/statusline.lua`)

`option.view.setup()` installs a 'statusline' that replaces Neovim's default
leading `%f` with the same repository notation this config writes into file
headers, ie. `~chewygumxx/nvim-config.git:main:/lua/util/statusline.lua`.
`M.value()` reads the option's _default_ (never its live value, which is what
makes it idempotent) and splices `M.items` over the `%<%f` it finds, so the rest
of that default (terminal exit code, LSP progress, `showcmd`, `b:keymap_name`,
the busy spinner, `vim.diagnostic.status()`, the ruler) survives untouched.

Three decisions there are load-bearing and each has a test that fails if it is
undone: the segment is a plain `%{}` and never the nested `%{%...%}` form, the
fallback emits a literal `%f` for Neovim to expand rather than reproducing it,
and nothing in the render path calls git. The **`statusline` skill** has those
in full, along with why `M.items` holds three items rather than one, why the
cache is a string rather than a table, and what invalidates it.

### Generated help (`doc/`, `lua/util/vimdoc.lua`, `scripts/genhelp.lua`)

`doc/nvim-config.txt` is this configuration's own `:help`, generated from the
configuration rather than written beside it. A config repository can host help
at all because `stdpath("config")` is always first on `runtimepath`; the only
plumbing that needs is `doc/tags`, which is tracked because lazy.nvim runs
`helptags` for the plugins it manages and never for the configuration directory.

The split is the point: `lua/util/vimdoc.lua` is pure rendering and touches
neither the session nor the filesystem, which is what lets
`tests/test_util_vimdoc.lua` assert column arithmetic without running any
`setup()`, while `scripts/genhelp.lua` harvests and writes.

`doc/` beside `docs/` is genuinely confusable, and is not a rename waiting to
happen: `doc/` is the only name Neovim's `runtimepath` scan accepts. `docs/` is
the browsable LuaCATS reference and `doc/` is `:help`. Both are generated,
tracked, and never edited by hand, which `.claude/hooks/block-generated.sh`
enforces.

The **`generated-output` skill** holds both trees: the regeneration procedure
and why it is verified with `git status --porcelain` rather than a diff, why
nothing is parsed out of the source, how plugin mappings are filtered against
`elide`/`condemn` and a spec's own condition, and the header and modeline
decisions. `/regen` runs it.

### WIP snapshots (`lua/util/wip.lua`)

`lua/util/wip.lua` periodically commits the in-memory text of a tracked buffer
onto `refs/wip/<branch>`, using git plumbing only, so unsaved work survives a
crash without any of it becoming visible repository state. HEAD, the real index
and the working tree are never written, so `git status` stays quiet and anything
already staged survives.

The **`wip` skill** has the mechanism, the debounce and eligibility rules, the
`XXWip` subcommands and the recovery commands.

### Other directories

- `lua/util/`: shared helpers used across the config, not plugin specs
  themselves: `lsp.lua` (above), `lazy.lua` (bootstraps lazy.nvim, see above),
  `header.lua` (backs the `XXInsertHeader` user command; generates this repo's
  file-header convention, see below), `wip.lua` (above), `minitest.lua` (this
  config's `MiniTest.Config`, in the one place both entry points can reach: the
  plugin spec's `config` and `scripts/minitest.lua`, since a spec whose `config`
  is a function never has its `opts` applied by lazy.nvim), `statusline.lua`
  (above), `markdown_list.lua` (above), `vimdoc.lua` (above), `claude.lua`,
  `git.lua`, `lua_checker.lua`, `markdown_table.lua`, `modeline.lua`, `nex.lua`,
  `shebang.lua`, `text.lua`, `treesitter.lua`, `visual_traversal.lua`, and
  `spec.lua`, which is superseded by `lua/plugin.lua`'s import groups and
  required by nothing.
- `lua/usercmd/`: user commands are defined centrally in `lua/usercmd/init.lua`,
  each delegating to a feature module (`lua/usercmd/*.lua` or `lua/util/*.lua`)
  rather than inlining logic.
- `tests/`: the mini.test suite, one `test_<module>.lua` per module under test,
  plus eight files that are not about one module. `test_spec.lua` is a smoke
  test over whole directories: every `lua/spec/*.lua` and `lsp/*.lua` parses,
  evaluates to a table and names the plugin its filename claims, every slug in
  `lua/plugin.lua`'s `elide`/`condemn` lists names a plugin some spec declares,
  and `mason-lspconfig`'s `ensure_installed` holds exactly the servers `lsp/`
  configures. `test_coverage.lua` is the registry: every module under `lua/`
  (bar `lua/spec/`) plus `init.lua` either has a test file named there or is
  exempt with a stated reason, and every `tests/*.lua` is matched by the
  collection glob, so a misnamed test file cannot sit in the directory looking
  collected; it derives `lua/util/X.lua` -> `tests/test_util_X.lua`, so a
  conventionally named test needs no registry entry. `test_filetype_modules.lua`
  drives the specialised filetype modules through `filetype.config`, the
  dispatcher that applies their `local_opts`/`hlgroup_defs`. `test_queries.lua`
  validates `queries/` (see below). `test_lockfile.lua` checks `lazy-lock.json`
  against the spec directory. `test_lazy_integration.lua` resolves the specs
  through a real lazy.nvim (see below). `test_claude_assets.lua` checks
  `.claude/` against the tree it describes: every rooted path its prose names
  still exists, every skill, command and agent folds its description with `>-`,
  every skill and agent declares the name it is filed under, every hook in
  `.claude/settings.json` points at something executable, and every skill is
  pointed at from this file. It cannot check that any of the prose is _true_,
  only that what it names is there. `helpers.lua` holds the shared git fixtures
  and is deliberately named so the `test_*.lua` glob does not collect it; test
  files load it with `dofile("tests/helpers.lua")`, since `tests/` is not on the
  Lua module path.

  Six conventions hold throughout. Modules that shell out to git are tested
  against real repositories built under `vim.fn.tempname()` by `helpers.repo()`
  and deleted in `after_each` (`test_util_git.lua`, `test_util_wip.lua`,
  `test_util_header.lua`, `test_util_statusline.lua`); that helper pins
  everything git would otherwise take from the machine, ie. the branch (`branch`
  is a required argument, not a default) since `init.defaultBranch` is not
  something a test should inherit, and `user.name`/`user.email` per repository
  since a CI runner has no global identity and `git commit` fails outright
  without one. `helpers.git` raises on a non-zero exit rather than returning
  `""`, because a swallowed setup failure resurfaces later as a puzzling
  assertion about something else. The whole suite shares one Neovim process, so
  anything that mutates session state (global options in `test_option.lua`,
  global keymaps in `test_keymap.lua`, augroups in `test_autocmd.lua`, highlight
  groups in `test_highlight.lua`) captures and restores it, since files run in
  alphabetical order and whatever is left set is inherited by every file after.
  Those same four files assert the _whole_ set they write and not merely that
  the documented entries were applied, by watching the writes (`vim.keymap.set`,
  `nvim_set_option_value`, `nvim_set_hl`, `nvim_create_augroup` are stubbed for
  the duration of one `setup()` call): the documented list doubles as the
  restore list, so an entry missing from it is an entry nothing puts back, which
  is how a visual-mode `gF` override once leaked into every later file. A stub
  of that kind is written with the real arity, since a narrower one retypes the
  field for the whole workspace and makes every real call site report
  `redundant-parameter`. And a case about something _not_ happening waits for a
  fence rather than sleeping: `util.wip`'s `report` argument makes it announce
  the no-op it reached, which replaced three fixed `vim.wait(2000, ...)` sleeps
  that were half the suite's runtime.

  Two files run a second Neovim, for different reasons. `test_init.lua` is the
  one that uses `MiniTest.new_child_neovim()`, because `init.lua`'s load order
  cannot be asserted in a process that has already required half of those
  modules; the child is started on `scripts/minimal_init.lua` and has
  `package.loaded["plugin"]` stubbed before `init.lua` is sourced, since
  `plugin.setup()` is the lazy.nvim bootstrap and would clone from the network.
  `test_lazy_integration.lua` instead spawns `scripts/lazy_merge.lua` through
  `vim.system` with `XDG_DATA_HOME`/`XDG_STATE_HOME`/`XDG_CACHE_HOME` pointed at
  a throwaway profile, because `stdpath` is fixed at startup and a real
  lazy.nvim run writes `state.json` and the lockfile into whichever profile it
  finds; lazy.nvim and mini.test are symlinked into that profile rather than
  cloned. Its own header records what it does and does not catch, established by
  mutation: it catches the `M.import()` wiring coming apart and any change in
  what lazy.nvim means by `ignore_installed`, and it cannot catch a slug moved
  between `elide` and `condemn`, since it reads those lists from the same module
  that drove the resolution.

  `test_queries.lua` validates `queries/` at three depths, because the grammars
  these queries target are not all available. Every file is parsed as the _query
  language_ using the `query` grammar Neovim bundles, which needs none of the
  target parsers and so covers all eight files; every `#predicate?` and
  `#directive!` has to resolve after `util.treesitter.setup()` has run, which is
  the parity gate against `lua/util/treesitter.lua`; and
  `vim.treesitter.query.parse` compiles a file against its own grammar, which
  reaches only the languages Neovim ships a parser for. Which those are is
  registered rather than discovered, so a parser arriving or leaving is a
  failure to read. Note `vim.treesitter.query.list_predicates()` and
  `list_directives()` return names already carrying their `?`/`!`, so appending
  one yields `eq??` and reports every core predicate as missing.

- `scripts/`: `minimal_init.lua` and `minitest.lua`, the headless test bootstrap
  and runner; `luals_untyped.lua` and `typecheck_sensitive.lua`, the
  annotation-coverage gate and the sensitive typecheck sweep; `lazy_merge.lua`,
  which runs lazy.nvim's real spec resolution and prints the result as JSON for
  `tests/test_lazy_integration.lua` to read; `gendoc.lua`, which renders
  `docs/`; and `genhelp.lua`, which renders `doc/`. The first four are described
  by the `gates` skill and the last two by `generated-output`. `lazy_merge.lua`
  asserts lazy.nvim is already installed rather than letting `util.lazy.setup`
  clone it, and forces `install.missing = false` plus `checker`/`rocks` off, so
  it never reaches the network.
- `docs/`: the browsable LuaCATS reference. Generated, tracked, and never edited
  by hand; gated by the `Docs` job. See the `generated-output` skill.
- `doc/`: this repository's own `:help`. Generated, tracked, and never edited by
  hand; gated by the `Help` job. See the `generated-output` skill.
- `queries/`: custom/overriding Tree-sitter queries (`markdown`,
  `markdown_inline`, `norg`, `norg_meta`, `comment`), picked up by Neovim's
  runtimepath convention. None carries an `; extends` comment, so each fully
  _replaces_ the runtime query for its language rather than adding to it;
  `test_queries.lua` records that per file, so changing it is a deliberate edit
  to the registry. `queries/comment/highlights.scm` is this repository's own,
  highlighting the file headers described under Conventions, and is the sole
  user of the three custom predicates `lua/util/treesitter.lua` registers
  (`adjacent?`, `last-matching?`, `header-line?`). `norg`/`norg_meta` are
  dormant while neorg is condemned, which is not the same as unchecked. Layout
  here is owned by `ts_query_ls format`, which is why the modelines and
  `.editorconfig`'s `[*.scm]` block say two spaces against the repository's
  usual four, and why the header box is contiguous in these files alone: the
  formatter collapses blank lines inside a leading comment run.
  `queries/CLAUDE.md` holds the rest, including why a single format pass does
  not converge. Adding those gates immediately found five `(#set! conceal "")`
  patterns in `markdown_inline/highlights.scm` with no capture to attach to,
  which Tree-sitter discards silently, so Markdown link concealment had never
  worked; the repair was `@conceal` and deliberately not upstream's
  `@markup.link`, whose removal that file documents as intentional.
- `snippets/`: a friendly-snippets-style manifest (`package.json`, using the
  VSCode `contributes.snippets` shape) plus per-language snippet JSON (currently
  `zsh.json`). LuaSnip itself is in `lua/plugin.lua`'s `elide` list, so the spec
  loads but the plugin does not.
- `types/`: `---@meta` declaration stubs for things LuaLS cannot see on its own.
  They are never required or executed, which is why `.husky/pre-commit` holds
  `selene` back from this directory: their intentional global declarations would
  otherwise be flagged as real-code bugs. Do not delete a stub because
  `workspace.library` appears to make it redundant.
- `.repo-metadata.jsonc`: schema-checked repo description/topics/license
  metadata, applied to the GitHub repo's own settings by the
  `sync-repo-metadata` GitHub Action on push to `main`
  (`.github/workflows/sync-repo-metadata.yaml`) whenever this file changes.
- `.github/scripts/`: `tool_version.py`, which prints the version `mise.toml`
  pins for a tool. The workflows read their pins through it rather than
  restating them, in two shapes: a bare tool key prints the version alone for
  `$(...)` capture, and `NAME=key` pairs print `NAME=version` for appending
  straight to `$GITHUB_ENV`. It exits non-zero on an unknown key, so a workflow
  cannot silently fall back to whatever the runner happened to have. Written in
  Python with `tomllib` rather than as a regex, since a `[tools]` entry is
  either a bare version string or a table carrying `matching` beside `version`,
  and the keys themselves contain the `:` and `/` that make them awkward regex
  subjects.
- `.github/actions/`: three composite actions the workflows share.
  `setup-neovim` installs, caches and PATHs the release `mise.toml` pins,
  reading it through `tool_version.py`; pass `version: nightly` for the canary,
  which is deliberately never cached. `install-mini-test` reads the tag
  `lua/spec/mini.test.lua` names, resolves it to a commit with
  `git ls-remote <url> "refs/tags/<tag>^{}"` and fetches that sha, asking Neovim
  for `stdpath("data")` rather than assuming it. It resolves rather than cloning
  the ref because these tags are annotated, so `refs/tags/v0.18.0` names a tag
  object (`6f129de`) and not the commit (`35c67cb`) it points at, and
  `git clone --depth 1 --branch` of such a ref makes git print
  `warning: ... is not a commit!` on every run: harmless, since the checkout and
  working tree were correct either way, but indistinguishable at a glance from a
  real failure. Resolving first also makes a tag absent upstream fail with a
  message naming it. Nothing reads the installed copy's git metadata, so the
  absent tag ref costs nothing, which was checked by running the suite against a
  copy carrying no tags. `install-lazy` clones the lazy.nvim commit
  `lazy-lock.json` pins, fetching that sha directly rather than cloning a
  branch, and caches it on the commit. `.github/workflows/test.yaml` runs the
  suite from one matrix, once on the pin and once on nightly with
  `continue-on-error`, so an upstream change is heard about before it reaches a
  release and is not reported as the fault of whichever pull request ran next.

## Conventions

- **File headers**: nearly every tracked file starts with an editor modeline, an
  `SPDX-License-Identifier: GPL-3.0-only` line, and a boxed comment giving the
  repo slug and the file's repo-relative path (e.g. `::: :/lua/util/lsp.lua`),
  using that file's line-comment syntax. These are auto-maintained by the
  `sync-header-metadata` GitHub Action on every push/PR to `main`
  (`.github/workflows/sync-header-metadata.yaml`), which commits corrections
  back as `chore: Sync header metadata`. Follow the header style of a sibling
  file of the same type rather than inventing one; CI fixes minor drift, and
  `XXInsertHeader` (backed by `lua/util/header.lua`) can generate one from
  scratch.
- **Markdown headers** are the same three parts wearing YAML: a `__cgxx: |`
  literal block scalar inside the frontmatter holds the modeline
  (`shiftwidth=2`, `foldlevel=3`), the SPDX line and the box, each indented two
  spaces and commented `#`, followed by `ctime:`, `title:`, `description:` and
  `tags:` keys and then the `#` heading. `util.header.frontmatter` renders the
  whole document head and is the only description of that shape:
  `util.header.insert` calls it for a plain Markdown buffer and
  `util.nex.render` calls it for a note, which differs only in filling in its
  own compound filetype, the `nex` repository and no SPDX line. The branch is
  gated on `filetype == "markdown"` exactly, so `markdown.claude` and
  `markdown.nex-note` do not take it. `util.text.yaml_scalar` is where the
  quoting rule lives, shared for the same reason; `util.nex.yaml_scalar` remains
  as a delegate because callers assembling a note have no reason to know that.
- **Indentation**: `.editorconfig` sets 4 spaces by default, 2 spaces for `*.md`
  and 2 for `*.scm`; LF endings, trailing whitespace trimmed, final newline
  inserted. Lua specifically also goes through `luafmt`'s own
  `max_line_width = 80`. The `*.scm` entry is not a preference:
  `ts_query_ls format` indents at two and offers no way to change it, so that
  block and the query modelines follow the formatter rather than the other way
  round.
- **Lua annotations vs. `luafmt`**: `luafmt` re-lays out call arguments, and it
  will happily move an inline `--[[@as T]]` cast onto a line of its own,
  silently detaching it from the expression it was annotating so that LuaLS
  stops honouring it. Where a cast is needed, assign to a `---@type`-annotated
  local instead. That same habit is what keeps `table.insert(list, s:gsub(...))`
  correct, since `gsub` returns a count as its second value which `table.insert`
  would read as an index. A multi-line `---@type` table shape is re-indented
  differently on each `luafmt` pass, reported as "formatting is not idempotent",
  so declare a `---@class` with one `---@field` per line instead.
  `---@diagnostic disable-next-line: <rule>` is the escape hatch for what LuaLS
  is right to flag but that cannot be written around, e.g. `duplicate-set-field`
  when a test stubs `vim.notify`, or `missing-fields` on a synthetic
  `command_args` table built to exercise a user command callback directly.
- **Reading a `luafmt` diff**: when it proposes exploding a whole call into the
  one-argument-per-line form, ie. turning `it("...", function()` into `it(`, a
  string, a `function()` and a closing `)`, the cause is almost never the call
  itself. It is one over-long line somewhere inside the body, and `luafmt`
  reformats the nearest enclosing call rather than the offending line. Shorten
  that line, usually by binding a long expression to a local, and the compact
  layout comes back. Chasing the proposed diff instead produces an ugly reformat
  that is also, briefly, idempotent, which makes it look correct.
- **Commit messages**: Conventional Commits, enforced by commitlint + husky.
  Scopes must come from this repo's fixed `scope.enum` (`hl`, `opt`, `ft`,
  `key`, `ucmd`, `acmd`, `lsp`, `spec`, `util`, `asset`, `claude`); do not
  invent ad hoc scopes like the parent dotfiles repo's `feat(nvim): ...` style.
  `claude` is for anything under `.claude/`, ie. hooks, skills, commands and
  agents. Headers are capped at 50 characters, so keep subjects short.
- **No AI co-author trailers**: do not add a `Co-Authored-By: Claude ...` (or
  similar) trailer unless explicitly asked to, on that specific commit.

## Behaviours no gate covers

Four things here are asserted only as far as a headless process can reach, so a
regression in them is silent and has to be looked at. All four were confirmed by
hand in a live Neovim on 2026-09-27, which is what makes them a baseline rather
than an open question; re-check the relevant one after touching it.

- The three statusline colours. `tests/test_util_statusline.lua` asserts the
  highlight _runs_ that `nvim_eval_statusline` reports, ie. that the right group
  covers the right byte range. Whether the palette in `lua/highlight.lua` is
  legible against the colorscheme is not something it can know. Truncation
  shortening from the left is likewise a property of `%<`'s position that only
  shows in a narrow window.
- The `gitcommit` header overflow. `tests/test_filetype_modules.lua` drives the
  module through `filetype.config` and checks the options and highlight links it
  declares; that `colorcolumn=51,73` actually lands where git's limits are needs
  a real commit buffer.
- `<leader>.` returning the same scratch buffer after a restart. That is snacks'
  `filekey` hashing over name, filetype, `v:count1`, cwd and branch plus a
  `root` under `stdpath("data")`, and persistence across processes is exactly
  what a single headless run cannot observe.
- which-key's group labels. The popup is where a prefix collision becomes
  visible, which is the reason the plugin was un-elided at all, so the labels
  being right is the feature rather than a detail of it. It is no longer the
  _only_ such place: `doc/nvim-config.txt`'s keymaps and plugin-mappings
  sections list the same ground and, being generated and diffed by CI, show a
  collision to a headless process. The popup is still the only place the
  grouping and its wording can be judged.
