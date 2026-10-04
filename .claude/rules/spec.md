---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/rules/spec.md
  #
  #

ctime: 2026-09-27
title: Plugin specs
paths:
  - "lua/spec/**/*"
tags:
  - llm
  - claude
---

# `lua/spec/` holds one spec per plugin

One file per plugin, each a self-contained `LazySpec`, named for the plugin's
own repository rather than its owner (`lua/spec/fzf-lua.lua` to
`ibhagwan/fzf-lua`). `tests/test_spec.lua` asserts every file in `lua/spec/`
parses, evaluates to a table, and names the plugin its filename claims, so a
rename in one place without the other fails the suite.

Carry `---@module "lazy"` and then `---@type LazyPluginSpec` on `local M`,
closing with `return M`. Add a second `---@module` when the plugin ships its own
type definitions. Once a spec grows, assign nested option tables after the fact
(`M.opts.picker = { ... }`) rather than inlining them, which is as much a
`luafmt` accommodation as a style choice.

Do not switch a plugin off from its own spec. Enabling and disabling is policy,
and policy lives in `lua/plugin.lua`'s `elide` and `condemn` lists. The
exception, and it is narrow, is a condition about the plugin rather than about
our use of it: `lazydev.nvim` keys off the presence of a `.luarc.json`, and
`mkdnflow` is held at `cond = false` by a crash documented inline.

**The trap worth knowing before you touch either list.** `elide` becomes
`cond = false` and `condemn` becomes `enabled = false`, but lazy.nvim's
`fix_cond` sets `enabled = false` on anything carrying `cond = false`, so after
the merge both groups sit in `Config.spec.disabled` and neither appears in
`Config.plugins`. The distinction survives in exactly one place,
`Config.spec.ignore_installed`, which holds the elided plugins and their
dependency closure so `:Lazy clean` leaves them on disk. Establishing that took
a real lazy.nvim run, which is what `tests/test_lazy_integration.lua` is for. A
consequence: the lockfile cannot tell you which group a plugin is in, because
lazy.nvim retains entries for both.

A slug in either list is a plain string, and a typo disables nothing and says
nothing. Two such entries survived unnoticed until `tests/test_spec.lua` began
asserting every slug names a plugin some spec declares, under both
`TERMUX_VERSION` states.

State inline why the plugin is here. Reading `lua/plugin.lua` tells you what is
switched off but never why, and a spec kept only for reference
(`telescope.nvim`) looks identical to one that loads.

Adding a spec means the lockfile. `lazy-lock.json` is tracked and
`tests/test_lockfile.lua` gates it, so a new plugin needs a `:Lazy sync` against
this checkout or an entry in that test's registry.

Where a plugin merges `opts` with `vim.tbl_deep_extend("force", ...)`, an entry
cannot be switched off by emptying or shortening its table: the merge recurses
whenever both sides are tables and arrays merge by index, so `{}` leaves the
default intact. `false` is what replaces a value. `lua/spec/hardtime.nvim.lua`
is the worked example, and the arrow keys depend on it whenever it is loaded; it
is elided at present, so what it protects is re-enabling it.
