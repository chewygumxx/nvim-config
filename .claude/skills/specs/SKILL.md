---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/skills/specs/SKILL.md
  #
  #

ctime: 2026-09-27
title: Plugin specs and the lazy.nvim bootstrap
name: specs
description: >-
  Add, change, enable or disable a plugin in this Neovim configuration. Use when
  editing anything under lua/spec/, lua/plugin.lua, lua/util/lazy.lua or
  lazy-lock.json, when a plugin is loaded or not loaded unexpectedly, when
  adding a leader-prefixed mapping, or when tests/test_spec.lua,
  test_lockfile.lua or test_lazy_integration.lua fails.
tags:
  - llm
  - claude
---

# Plugin specs and the lazy.nvim bootstrap

## Adding a spec

One file per plugin under `lua/spec/`, named after the plugin's own repo name,
so `lua/spec/fzf-lua.lua` is `ibhagwan/fzf-lua`. `tests/test_spec.lua` asserts
that every file parses, evaluates to a table and names the plugin its filename
claims, so a mismatch fails rather than loading nothing.

Before finishing, check each of these:

1. The file carries this repository's header, ie. modeline, SPDX line and boxed
   slug/path comment. Follow a sibling spec rather than inventing one.
2. If the spec declares `keys`, run `scripts/genhelp.lua`, since plugin mappings
   are read statically into `doc/nvim-config.txt`.
3. If the spec declares a leader prefix, check it against the prefixes below and
   label it in `lua/spec/which-key.nvim.lua`.
4. If the plugin is an LSP server, `mason-lspconfig`'s `ensure_installed` and
   `lsp/` must hold exactly the same set; `tests/test_spec.lua` asserts that
   parity.
5. Regenerate `lazy-lock.json` from **this** checkout, not the deployed one (see
   below).

## Enabling and disabling

Centralised in `lua/plugin.lua`, not written onto each spec. `M.elide` and
`M.condemn` are lists of `owner/repo` slugs, and `M.factory(group)` turns either
into a `LazySpecImport` of bare `{ slug, cond = false }` /
`{ slug, enabled = false }` overrides, which lazy.nvim merges into each plugin's
real spec regardless of import order. `M.import()` returns `{ import = "spec" }`
followed by both groups, and `M.setup()` hands that to `util.lazy.setup` as
`spec`. Termux is handled here too, by appending the three mason plugins to
`M.condemn` at module load, since mason has no toolchain there.

The distinction is deliberate: `cond = false` leaves a plugin installed but
never loaded, `enabled = false` takes it out altogether.

**It survives the merge in exactly one place, which is not the obvious one.**
lazy.nvim's `fix_cond` sets `enabled = false` on anything carrying
`cond = false`, so elided and condemned plugins both land in
`Config.spec.disabled` and both leave `Config.plugins` entirely. Only
`Config.spec.ignore_installed` separates them: it holds the elided plugins and
their dependency closure, so `:Lazy clean` leaves them on disk, and condemned
plugins never enter it. `tests/test_lazy_integration.lua` asserts this, and it
needed a real lazy.nvim run to establish it.

Two consequences. A slug in either list is a plain string that nothing else
validates, so a typo disables nothing and says nothing; two such entries were
found and repaired in `fix(spec): Repair stale elide and condemn slugs`, one of
which had never matched since it was written. `tests/test_spec.lua` now asserts
every slug in both lists, under both `TERMUX_VERSION` states, names a plugin
some spec actually declares.

And the list is not the only place a plugin can be switched off. A spec may
carry its own condition where that condition is specific to the plugin rather
than a policy about it, and two currently do on top of being listed:
`lua/spec/lazydev.nvim.lua` (`enabled = vim.fs.root(0, ".luarc.json") == nil`)
and `lua/spec/mkdnflow.lua` (`cond = false`, with the crash it works around
explained inline). **Reading only `lua/plugin.lua` tells you what is disabled,
but not always why.**

## Leader prefixes

Worth knowing before adding a keymap, because two plugins once claimed the same
one. `<leader>a` is `lua/spec/claudecode.nvim.lua`'s and `<leader>H` is
`lua/spec/herdr-nvim.lua`'s.

herdr used to be on `<leader>a` too and lost five keys (`ac`, `ar`, `aa`, `as`,
`af`) to claudecode without saying so, since its `apply_keymaps` refuses to
clobber a key another mapping holds and claudecode's arrive first as lazy.nvim's
load stubs. herdr hardcodes its prefix, so the move is `opts.keymaps = false`
plus its whole set re-declared in the spec's `keys`, bracket motions (`]n`/`[n`,
`]r`/`[r`) included, since that switch withholds everything rather than only the
leader keys. A mapping a later herdr release adds will therefore not appear
until it is added there, and `:checkhealth herdr-nvim` is where to notice.

`lua/spec/which-key.nvim.lua` labels every prefix and is no longer elided, which
is what makes a collision of that kind visible rather than silent. It
deliberately labels no prefix owned by `lua/spec/mkdnflow.lua`, whose
`cond = false` means those keys do not exist.

## The bootstrap (`lua/util/lazy.lua`)

`M.defaults` is the full lazy.nvim options table: the repo URL and branch to
`git clone` if lazy.nvim is not present yet, `dev.patterns = { "chewygumxx" }`
so a local `~/dev/chewygumxx`-owned checkout wins over git when present,
`checker` auto-disabled under Herdr/Termux via `HERDR_ENV`/`TERMUX_VERSION` env
checks. `M.setup(opts)` deep-merges caller opts over those defaults, clones
lazy.nvim via `M.install()` if missing, then calls
`require("lazy").setup(opts)`. `lua/plugin.lua`'s `M.setup()` passes the one
machine-specific override it needs, SSH versus HTTPS clone URLs via
`git.url_format`.

`M.defaults` names `folke/lazy.nvim` on branch `stable`, and both fields are
read by `M.install()` alone. They are bootstrap-only by construction:
lazy.nvim's own options table has no `branch` key, and an installed copy manages
itself through a spec it hardcodes as `{ "folke/lazy.nvim" }` with no branch, so
`Git.get_branch` falls back to `origin/HEAD` and the first `:Lazy update` on any
machine moves that copy to the remote default and writes _that_ into
`lazy-lock.json`. `stable` therefore describes what a machine without lazy.nvim
clones and nothing after. Pinning it for good would take a real
`lua/spec/lazy.nvim.lua` declaring the branch, which would also mean dropping
the `lazy.nvim` entry from `tests/test_lockfile.lua`'s `unspecced` registry;
that was considered and deliberately not done. `.github/actions/install-lazy`
sidesteps the whole question by fetching the locked commit by sha.

`dev.patterns` currently matches no spec at all, since no `lua/spec/*.lua` names
a `chewygumxx/`-owned plugin.

## `lazy-lock.json`

**Tracked.** `M.defaults.lockfile` is lazy.nvim's own default, ie. inside
`stdpath("config")`, which is a checkout of this repository on every machine it
is deployed to. It used to be relocated beside `state.json` under
`stdpath("state")`, which classified the lock as machine state. Tracking it buys
`:Lazy restore` giving every machine the same commits, and an honest `hashFiles`
cache key for a plugin install in CI.

One file serves Arch, Termux and Herdr despite their differing plugin sets,
because lazy.nvim's writer keeps the entries of plugins it is not currently
managing, ie. anything in `Config.spec.disabled` or
`Config.spec.ignore_installed`. So the mason trio condemned under Termux keeps
its pin when a Termux sync writes the file. That same retention is why entries
exist for everything `M.elide` and `M.condemn` name: **an entry records a pin to
return to, not that the plugin is in use**, and the lock cannot be used to tell
an elided plugin from a condemned one.

`.prettierignore` excludes it because lazy.nvim writes one line per plugin and
prettier expands each across four, so whichever ran last would be undone by the
other. The generator wins, being the one that runs without being asked.

The `mini.test` entry agrees with the `tag = "v0.18.0"` that
`lua/spec/mini.test.lua` names, so local runs and CI use one framework commit.
That agreement is recorded as a `branch`/`commit` pair rather than a tag, since
lazy.nvim's writer resolves a tag to the commit it points at (`35c67cb`, ie.
`v0.18.0^{commit}`, not the annotated tag object `git rev-parse v0.18.0`
prints).

Regenerating the lock from this checkout rather than the deployed one takes:

```sh
NVIM_APPNAME=nvim-config XDG_CONFIG_HOME=$HOME/dev nvim
```

since `stdpath("config")` is where `M.defaults.lockfile` writes and
`~/.config/nvim` is a separate checkout.

## Individual specs worth reading first

`lua/spec/hardtime.nvim.lua`, for one non-obvious reason that generalises to
**any plugin merging its options with `vim.tbl_deep_extend("force", ...)`**: an
entry cannot be switched off through `opts` by emptying or shortening it,
because that merge recurses whenever both sides are tables and arrays merge by
index, so `{}` or `{ "n" }` leaves the default's `{ "n", "i" }` intact. `false`
is what replaces the value, and hardtime's handler loop then maps nothing at all
(`if mode then vim.keymap.set(...)`). That is how the arrow keys stay usable,
which is not a preference: `lua/spec/blink.cmp.lua` maps `<Up>`/`<Down>` to
`select_prev`/`select_next`, so hardtime's default insert-mode arrow blocking
would take completion-menu navigation with it. `types/hardtime.nvim.d.lua` types
the option table accordingly, ie. `table<string, string[] | false>`.

`lua/spec/snacks.nvim.lua` is `lazy = false` at `priority = 1000` because other
specs reference it, and it enables three of snacks' modules and nothing else.
`picker` exists only for `util.nex`'s tag multi-select, which needs a picker
that can return several items, with `ui_select = false` so it does not take over
`vim.ui.select` globally; `fzf-lua` remains the finder. `scratch` backs
`<leader>.` and `<leader>S`, and its `filekey` is the whole feature: the file a
keymap opens is hashed over name, filetype, `v:count1`, cwd and git branch, so
one binding yields a different buffer per project and per branch, and
`3<leader>.` is a third one. Its `root` is stated explicitly rather than left
implicit, since a scratch file is machine state under `stdpath("data")`, which
is the opposite call from `lazy-lock.json` living inside `stdpath("config")`.
Whether `<leader>.` really returns the same buffer after a restart is a hand
check and cannot be anything else: persistence across processes is precisely
what a single headless run cannot observe.

`lua/spec/claudecode.nvim.lua` sets three options and leaves the rest
upstream's. `terminal.provider = "snacks"` is named rather than left as
`"auto"`, since snacks is a declared dependency that loads eagerly and the
discovery can only reach the same answer more slowly. `focus_after_send = true`
departs from the default deliberately and pairs with the provider: the plugin
warns at setup when a provider cannot move focus, which is why the two belong
together. It carries no `{ "<leader>a", nil }` group placeholder any more,
because which-key labels the prefix now and an entry with no right-hand side is
a lazy-load trigger on `<leader>a` itself.

`lua/spec/starry.lua`'s `config()` calls `vim.cmd("colorscheme starry")`
directly; colourscheme selection is inlined rather than indirected.
`lua/spec/fzf-lua.lua` is the fuzzy finder, and `lua/spec/telescope.nvim.lua` is
still present but elided, so it is a spec kept for reference rather than a
fallback that loads.

`lua/util/spec.lua` predates all of this and held the same idea, a
`{ import = "spec" }` entry plus one elision list. Nothing requires it any more.
