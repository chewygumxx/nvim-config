# CLAUDE.md

Absolutely no em dashes are to be employed within this repository.

Ensure any printed conversation output line length is limited to 80 characters
except where it may be unfeasable to do so eg. URL.

## What this repository is

`chewygumxx/nvim-config`: a standalone Neovim configuration, plugin-managed by
[lazy.nvim](https://lazy.folke.io). It is not part of the dotfiles repo; it has
its own git history, its own commitlint/CI setup, and no chezmoi involvement.

## Commands

There is no build step. Linting/formatting/typechecking:

- **Lua**: format with `luafmt` (EmmyLua formatter, config in `.luafmt.toml`),
  lint with `selene` (config in `selene.toml`,
  `std = "lua51+vim+luajit +busted"`, backed by
  `vim.yml`/`luajit.yml`/`busted.yml`). Neither ships as an npm devDependency;
  both must be on `PATH` (installed from pinned GitHub releases in CI, see
  `.github/workflows/lint-config.yaml`). Run over one file:
  `luafmt --check --verify path/to/file.lua && selene path/to/file.lua`.
- **TOML**: `tombi format --check --offline` /
  `tombi lint --error-on-warnings --offline` (`.tombi.toml`).
- **JSON/YAML**: `npx prettier --check <files>`.
- **Lua typecheck**: `lua-language-server --check=. --checklevel=Warning`, which
  is repo-wide rather than per-file, and needs `VIMRUNTIME` exported so that
  `$VIMRUNTIME/lua` in `.luarc.json`'s `workspace.library` resolves.
  `diagnostics.groupFileStatus` enables `luadoc`/`strict`/`strong`/`type-check`
  at `Any`, so annotation drift fails the check and not just genuine type
  errors; `missing-fields`, `duplicate-set-field`, `need-check-nil`,
  `no-unknown` and `param-type-mismatch` are the ones that bite in practice. Run
  by `.husky/pre-commit` and, since it is skippable there, again by the
  `Typecheck` step of the `LuaCATS` job in `.github/workflows/lint-config.yaml`.
  Neither trusts the exit code, which some releases leave at 0 with problems
  found; both read the `no problems found` summary line instead.
- **Sensitive Lua typecheck**:
  `nvim --headless -u scripts/minimal_init.lua -l scripts/typecheck_sensitive.lua`
  runs the same repo-wide check at `Hint`, ie. everything the gate ignores.
  Nothing runs it automatically: it is a sweep to read, not a gate to satisfy.
  Run through Neovim so the child inherits `$VIMRUNTIME`.
- **Annotation coverage**:
  `nvim --headless -u scripts/minimal_init.lua -l scripts/luals_untyped.lua`
  fails if LuaLS cannot infer anything more specific than `any`/`unknown` under
  `lua/`, `lsp/` or `init.lua`. Its pass signal is the absence of output, so it
  is written to fail closed: a failed or timed-out `inlayHint` request, a client
  that never finished indexing, an empty file list from the wrong cwd, or a run
  that saw no hints at all is fatal rather than an empty result.
- **Tests**:
  `nvim --headless -u scripts/minimal_init.lua -l scripts/minitest.lua`. The
  suite is [mini.test](https://github.com/echasnovski/mini.test), driven through
  its busted-style `describe`/`it`/`before_each`/`after_each` wrappers with
  `MiniTest.expect.equality` as the assertion. `scripts/minimal_init.lua`
  deliberately does not source `init.lua` (its own header explains why) and
  _replaces_ the runtimepath with this checkout, `$VIMRUNTIME` and the
  already-installed `mini.test`: `stdpath("config")` and the site directories
  are removed rather than merely outranked, since for anyone running the
  deployed copy of this config they hold a second copy of every module under
  test, and a module deleted or renamed in the checkout would keep resolving
  from there. `mini.test` must exist under `stdpath("data")/lazy/mini.test`,
  which the bootstrap asserts. `scripts/minitest.lua` is the single entry point
  shared by headless runs and `:MiniTestRun`; both apply
  `lua/util/minitest.lua`'s options, so what is collected and how it executes is
  the same either way. That runner is also written to fail closed, for the
  reason `scripts/luals_untyped.lua` is: `mini.test` ends a run with `cquit 0`
  whenever nothing failed, so a run that collected nothing exits 0 and reports
  success. It therefore raises unless `lua/util/minitest.lua` is readable from
  the cwd and `collect.find_files` returned at least one file. Set
  `MINITEST_PATTERN` to a Lua pattern to run only the cases whose description
  matches it
  (`MINITEST_PATTERN=util.wip nvim --headless -u scripts/minimal_init.lua -l scripts/minitest.lua`),
  which is the headless counterpart of `:MiniTestRunFile`. `mini.test` itself is
  pinned by `tag` in `lua/spec/mini.test.lua`, and CI reads that tag out of the
  spec rather than naming its own, so the pre-commit gate and CI cannot run
  different versions of the framework.
- **Commit message typecheck**: `npm run typecheck` (runs `tsc` scoped to
  `.commitlintrc.mts` only, per `tsconfig.json`).
- **Interactive commit**: `npm run commit` (commitizen, via
  `@commitlint/cz-commitlint`, patched by `patches/` to show `fullName` labels
  instead of raw enum keys in the type/scope prompts).

`.husky/pre-commit` runs `luafmt --write` + `selene`, `tombi format` +
`tombi lint`, and `prettier --write` on staged files matching each type
(silently skipping any tool that isn't on `PATH`), then re-stages the results.
`selene` is held back from `types/`, whose `---@meta` stubs would otherwise be
flagged for their intentional global declarations. It then gates the commit on
two whole-repo checks that ignore what was staged: `lua-language-server --check`
at `Warning` whenever any `*.lua` file is staged, and the full `mini.test` suite
whenever anything under `lua/`, `tests/`, `scripts/`, `lsp/`, `queries/` or
`init.lua` is. Each asks `git diff --cached` for its own file list rather than
reading a variable another function left behind. Both are skipped when
`nvim`/`lua-language-server` are absent, which is the reason CI repeats the
LuaLS check rather than trusting the hook. `.husky/commit-msg` enforces
commitlint.

Unlike the dotfiles repo's free-form scopes, this repo's `.commitlintrc.mts`
defines a fixed `scope.enum` (`hl`, `opt`, `ft`, `key`, `ucmd`, `acmd`, `lsp`,
`spec`, `util`, `asset`, each with a `fullName`/`description` used to label
`npm run commit`'s prompt) alongside its `type.enum` (`feat`, `fix`, `tweak`,
`chore`, `style`, `docs`, `ci`, `refactor`, `perf`, `build`, `test`, `revert`);
scope is optional, and per `scope-delimiter-style` multiple scopes can be joined
with `/`. `header-max-length` caps the whole `type(scope): Subject` header at 50
characters, so keep subjects short.

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
`FileType`-triggered overrides win), `autocmd`, `usercmd`, `util.lazy` (after
keymap/filetype/autocmd, since lazy-loaded plugin specs key off
`vim.g.mapleader`, filetype autocmds, and augroups defined earlier), then
`highlight` last (after `util.lazy`, so it overwrites whatever the
colorscheme/treesitter plugins set).

There is no `cgxx` settings-as-plugin indirection layer and no
`lua/plugin_manager.lua`; earlier revisions of this file described one, but it
has since been removed. Machine- and environment-specific choices (colorscheme,
fuzzy finder, Herdr/Termux checks) are now made directly at the point of use in
the relevant module or plugin spec, described below.

### Plugin bootstrap (`lua/util/lazy.lua`) and specs (`lua/spec/`)

`lua/util/lazy.lua` is this config's lazy.nvim bootstrap. `M.defaults` is the
full lazy.nvim options table (the repo URL/branch to `git clone` if lazy.nvim
itself isn't present yet, `dev.patterns = { "chewygumxx" }` so a local
`~/dev/chewygumxx-owned` checkout wins over git when present, `checker`
auto-disabled under Herdr/Termux via `HERDR_ENV`/`TERMUX_VERSION` env checks,
etc.), and `M.setup(opts)` deep-merges caller opts over those defaults, clones
lazy.nvim via `M.install()` if missing, then calls
`require("lazy").setup(opts)`. `lua/plugin.lua`'s `M.setup()` calls
`require("util.lazy").setup(lazyconf)` with the one machine-specific override it
needs (SSH vs. HTTPS clone URLs via `git.url_format`).

Plugin specs load through lazy.nvim's own `{ import = "spec" }` mechanism,
walking `lua/spec/*.lua` directly; there is no repo-specific spec resolver. Each
file is a self-contained `LazySpec` for one plugin, matching the plugin's own
repo name (e.g. `lua/spec/fzf-lua.lua` -> `ibhagwan/fzf-lua`).
`M.defaults.spec = "spec"` is the bare form of that, but `lua/plugin.lua`
overrides it with `M.import()`, described next.

Enabling and disabling is centralised in `lua/plugin.lua`, not written onto each
spec. `M.elide` and `M.condemn` are lists of `owner/repo` slugs, and
`M.factory(group)` turns either into a `LazySpecImport` of bare
`{ slug, cond = false }` / `{ slug, enabled = false }` overrides, which
lazy.nvim merges into each plugin's real spec regardless of import order. The
distinction is deliberate: `cond = false` leaves a plugin installed but never
loaded, `enabled = false` takes it out altogether. `M.import()` returns
`{ import = "spec" }` followed by both groups, and `M.setup()` hands that to
`util.lazy.setup` as `spec`. Termux is handled here too, by appending the three
mason plugins to `M.condemn` at module load, since mason has no toolchain there.

Two consequences worth knowing. A slug in either list is a plain string that
nothing else validates, so a typo disables nothing and says nothing (two such
entries were found and repaired in
`fix(spec): Repair stale elide and condemn slugs`, one of which had never
matched since it was written); `tests/test_spec.lua` now asserts every slug in
both lists, under both `TERMUX_VERSION` states, names a plugin some spec
actually declares. And the list is not the only place a plugin can be switched
off: a spec may still carry its own condition where that condition is specific
to the plugin rather than a policy about it, and two currently do on top of
being listed, `lua/spec/lazydev.nvim.lua`
(`enabled = vim.fs.root(0, ".luarc.json") == nil`) and `lua/spec/mkdnflow.lua`
(`cond = false`, with the crash it works around explained inline). Reading only
`lua/plugin.lua` therefore tells you what is disabled, but not always why.

Colourscheme selection is inlined the same way: `lua/spec/starry.lua`'s
`config()` calls `vim.cmd("colorscheme starry")` directly.
`lua/spec/fzf-lua.lua` is the fuzzy finder; `lua/spec/telescope.nvim.lua` is
still present but elided, so it is a spec kept for reference rather than a
fallback that loads.

`lua/util/spec.lua` predates all of this and held the same idea (a
`{ import = "spec" }` entry plus one elision list). Nothing requires it any
more.

### LSP (`lsp/`, `lua/spec/nvim-lspconfig.lua`, `lua/util/lsp.lua`)

This config uses Neovim's **native** `vim.lsp.config`/`vim.lsp.enable` mechanism
(0.11+), not `nvim-lspconfig`'s old `setup{}` API. Per-server config tables live
in `/lsp/<name>.lua` at the repo root: Neovim's built-in runtimepath convention,
auto-discovered by `vim.lsp.enable()`. `mason-lspconfig.nvim`
(`lua/spec/mason-lspconfig.nvim.lua`) installs everything in `ensure_installed`
and calls `vim.lsp.enable()` for all of them via `automatic_enable = true`. On
Termux the whole mason trio is disabled, since it lacks mason's toolchain, but
that gate lives in `lua/plugin.lua`'s `condemn` list rather than on the specs
themselves. `lua/util/lsp.lua` centralizes what would otherwise be duplicated
per-server: capabilities (merges blink.cmp's completion capabilities over
Neovim's defaults), `vim.diagnostic.config()`, and the buffer-local keymaps
wired up on every `LspAttach` (`gd`, `gr`, `K`, `<leader>ca`, etc.), so a
per-server `lsp/*.lua` only needs to add what's actually server-specific
(`root_markers`, extra `capabilities`, an `on_attach` for highlight groups).

### Filetype system (`lua/filetype/`)

`lua/filetype/init.lua`'s `M.filetypes` table holds custom filetype _detection_
patterns Neovim doesn't recognize out of the box (e.g. mapping
`*.service`/`*.conf` to `dosini`, `ignore`/`.chezmoiignore` to `gitignore`,
gnupg/hypr/zsh paths to `gpg`/`hyprlang`/`zsh`); `M.setup()` registers it via
`vim.filetype.add()`. Separately, `M.modmap` maps already-detected filetypes to
specialised per-filetype modules, dispatched by `M.config()` off a `FileType`
autocmd registered in `M.autocmd()`; several real filetypes can route to one
module (`dosini`, `confini`, `gitconfig`, `cfg`, `editorconfig` all ->
`lua/filetype/dosini.lua`). A specialised module is mostly declarative:
`M.local_opts` (buffer-local options) and `M.hlgroup_defs` (highlight links,
applied once per session) are read and applied generically by `M.config()`; a
module only needs its own `M.setup(opts)` when it has logic beyond that, e.g.
`lua/filetype/help.lua` repositioning the help window.

### Statusline (`lua/util/statusline.lua`)

`option.view.setup()` installs a 'statusline' that replaces Neovim's default
leading `%f` with the same repository notation this config writes into file
headers, ie. `~chewygumxx/nvim-config.git:main:/lua/util/statusline.lua`.
`M.value()` reads the option's _default_ (never its live value, which is what
makes it idempotent) and splices `M.items` over the `%<%f` it finds, so the rest
of that default (terminal exit code, LSP progress, `showcmd`, `b:keymap_name`,
the busy spinner, `vim.diagnostic.status()`, the ruler) survives untouched.

Three decisions are load-bearing, and each has a test that fails if it is
undone. The segment is a plain `%{}` and never the nested `%{%...%}` form,
because only the latter re-parses its result for statusline items and would
mangle any "%" in a filename. The fallback is a second item emitting the literal
string `%f` for Neovim to expand, rather than this module reproducing it,
because `%f` is not `nvim_buf_get_name`: it also supplies the bracketed names of
special buffers and shortens against `$HOME` and the cwd. And nothing in the
render path calls git: `M.segment` is a cache read, a miss schedules one async
`util.git.info` call and falls back to `%f` for that redraw, and `store` gates
its `redrawstatus!` on the value actually changing, since redrawing
unconditionally turns any buffer appearing mid-redraw into a livelock.

Filling is lazy on cache miss rather than on `BufEnter`, so a buffer displayed
by any route at all fills itself in, which leaves `M.autocmd()` responsible only
for invalidation: `BufFilePost`/`BufWritePost` per buffer,
`FocusGained`/`VimResume`/`ShellCmdPost`/`TermClose` for every buffer (a
checkout elsewhere), and `BufDelete`/`BufWipeout` to release the in-flight
marker. That marker is a module-local table rather than a `vim.b` variable,
because `M.segment` runs during statusline evaluation and has no business
mutating buffer state; it also carries the buffer _name_ the in-flight call was
issued for, which is how a late answer recognises that a rename or a refresh has
superseded it.

### WIP snapshots (`lua/util/wip.lua`)

`lua/util/wip.lua` periodically commits the in-memory text of a tracked buffer
onto `refs/wip/<branch>`, so unsaved work survives a crash without any of it
becoming visible repository state. It uses git plumbing only, from one POSIX
`sh` script run through a single async `vim.system` call with the buffer
serialised onto stdin: `hash-object -w` writes the blob, a throwaway
`GIT_INDEX_FILE` under the git dir then absorbs `read-tree` +
`update-index --cacheinfo` + `write-tree`, and `commit-tree` + `update-ref` move
the ref. HEAD, the real index and the working tree are never written, so
`git status` stays quiet and anything already staged survives; `refs/wip/*` sits
outside `refs/heads/*`, which keeps it invisible to
`git branch`/`git log`/`git push` while still counting as a gc root.
`commit-tree` bypasses the husky hooks by construction, and signing is forced
off via `-c commit.gpgsign=false` because a gpg passphrase prompt has nowhere to
go from an async `vim.system` call and would hang the snapshot.

Snapshots are debounced (`M.debounce`, 2000 ms) off `TextChanged`/`TextChangedI`
and taken immediately on `BufWritePost`/`BufLeave`/`FocusLost`; one whose tree
matches the ref tip exits before `commit-tree`, which is what makes those extra
checkpoints nearly free. Eligibility is "inside a worktree and known to
`git ls-files --error-unmatch`", cached per buffer in `vim.b.cgxx_wip_location`
and invalidated on `BufWritePost` so a newly tracked file starts snapshotting.
`vim.g.cgxx_wip` and `vim.b.cgxx_wip` are the off switches; `XXWip` takes
`toggle`/`enable`/`disable`/`snapshot` plus a bang-only `drop`. Recovery is
plain git: `git log refs/wip/<branch>`, `git show refs/wip/<branch>:<path>`,
`git restore --source=refs/wip/<branch> -- <path>`. Nothing prunes the ref, so
it grows until `XXWip! drop`, and it is not pushed or fetched without an
explicit `refs/wip/*` refspec.

### Other directories

- `lua/util/`: shared helpers used across the config, not plugin specs
  themselves: `lsp.lua` (above), `lazy.lua` (bootstraps lazy.nvim, see above),
  `header.lua` (backs the `XXInsertHeader` user command; generates this repo's
  file-header convention, see below), `wip.lua` (above), `minitest.lua` (this
  config's `MiniTest.Config`, in the one place both entry points can reach: the
  plugin spec's `config` and `scripts/minitest.lua`, since a spec whose `config`
  is a function never has its `opts` applied by lazy.nvim), `statusline.lua`
  (above), `claude.lua`, `git.lua`, `lua_checker.lua`, `markdown_table.lua`,
  `modeline.lua`, `nex.lua`, `shebang.lua`, `text.lua`, `treesitter.lua`,
  `visual_traversal.lua`, and `spec.lua`, which is superseded by
  `lua/plugin.lua`'s import groups and required by nothing.
- `lua/usercmd/`: user commands are defined centrally in `lua/usercmd/init.lua`,
  each delegating to a feature module (`lua/usercmd/*.lua` or `lua/util/*.lua`)
  rather than inlining logic.
- `tests/`: the mini.test suite, one `test_<module>.lua` per module under test,
  plus four files that are not about one module. `test_spec.lua` is a smoke test
  over whole directories: every `lua/spec/*.lua` and `lsp/*.lua` parses,
  evaluates to a table and names the plugin its filename claims, every slug in
  `lua/plugin.lua`'s `elide`/`condemn` lists names a plugin some spec declares,
  and `mason-lspconfig`'s `ensure_installed` holds exactly the servers `lsp/`
  configures. `test_coverage.lua` is the registry: every module under `lua/`
  (bar `lua/spec/`) plus `init.lua` either has a test file named there or is
  exempt with a stated reason, and every `tests/*.lua` is matched by the
  collection glob, so a misnamed test file cannot sit in the directory looking
  collected. `test_filetype_modules.lua` drives the specialised filetype modules
  through `filetype.config`, the dispatcher that applies their
  `local_opts`/`hlgroup_defs`. `helpers.lua` holds the shared git fixtures and
  is deliberately named so the `test_*.lua` glob does not collect it; test files
  load it with `dofile("tests/helpers.lua")`, since `tests/` is not on the Lua
  module path.

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

  `test_init.lua` is the one file that works through
  `MiniTest.new_child_neovim()`, because `init.lua`'s load order cannot be
  asserted in a process that has already required half of those modules. The
  child is started on `scripts/minimal_init.lua` and has
  `package.loaded["plugin"]` stubbed before `init.lua` is sourced, since
  `plugin.setup()` is the lazy.nvim bootstrap and would clone from the network.

- `scripts/`: `minimal_init.lua` and `minitest.lua`, the headless test bootstrap
  and runner; `luals_untyped.lua` and `typecheck_sensitive.lua`, the
  annotation-coverage gate and the sensitive typecheck sweep. All four are
  described under Commands.
- `queries/`: custom/overriding Tree-sitter queries (`markdown`,
  `markdown_inline`, `norg`, `norg_meta`, `comment`), picked up by Neovim's
  runtimepath convention.
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
- `.github/actions/`: two composite actions the workflows share. `setup-neovim`
  holds the single Neovim pin (its `version` input's default) and installs,
  caches and PATHs that release; pass `version: nightly` for the canary, which
  is deliberately never cached. `install-mini-test` clones the tag
  `lua/spec/mini.test.lua` names, asking Neovim for `stdpath("data")` rather
  than assuming it. `.github/workflows/test.yaml` runs the suite twice, once on
  the pin and once on nightly with `continue-on-error`, so an upstream change is
  heard about before it reaches a release and is not reported as the fault of
  whichever pull request ran next.

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
- **Indentation**: `.editorconfig` sets 4 spaces by default, 2 spaces for
  `*.md`; LF endings, trailing whitespace trimmed, final newline inserted. Lua
  specifically also goes through `luafmt`'s own `max_line_width = 80`.
- **Lua annotations vs. `luafmt`**: `luafmt` re-lays out call arguments, and it
  will happily move an inline `--[[@as T]]` cast onto a line of its own,
  silently detaching it from the expression it was annotating so that LuaLS
  stops honouring it. Where a cast is needed, assign to a `---@type`-annotated
  local instead. `---@diagnostic disable-next-line: <rule>` is the escape hatch
  for what LuaLS is right to flag but that cannot be written around, e.g.
  `duplicate-set-field` when a test stubs `vim.notify`, or `missing-fields` on a
  synthetic `command_args` table built to exercise a user command callback
  directly.
- **Commit messages**: Conventional Commits, enforced by commitlint + husky (see
  Commands above). Scopes must come from this repo's fixed `scope.enum` (`hl`,
  `opt`, `ft`, `key`, `ucmd`, `acmd`, `lsp`, `spec`, `util`, `asset`); do not
  invent ad hoc scopes like the parent dotfiles repo's `feat(nvim): ...` style.
  Headers are capped at 50 characters, so keep subjects short.
- **No AI co-author trailers**: do not add a `Co-Authored-By: Claude ...` (or
  similar) trailer unless explicitly asked to, on that specific commit.
