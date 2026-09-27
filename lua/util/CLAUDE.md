---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/lua/util/CLAUDE.md
  #
  #

ctime: 2026-09-27
title: CLAUDE.md
description: >-
  Conventions for the shared helper modules, including the two annotation habits
  luafmt will otherwise undo.
tags:
  - llm
  - claude
---

# CLAUDE.md

A module here opens `local M = {}` and closes `return M`. `M.setup` is _not_
part of the contract, unlike `lua/filetype/`, where the dispatcher calls it:
only some modules have one, and a `util` module is a library first. Put it here
when two callers would otherwise each grow their own copy, and say so in the doc
comment. `util.text.yaml_scalar` states the case plainly, that a second copy
would be a second opinion on what YAML needs quoting.

**Two annotation habits exist because `luafmt` will otherwise silently undo the
annotation.**

Never write an inline `--[[@as T]]` cast. `luafmt` re-lays out call arguments
and will happily move the cast onto a line of its own, detaching it from the
expression it was annotating, after which LuaLS stops honouring it and nothing
reports a problem. Assign to a `---@type`-annotated local instead. The same
habit is what keeps `table.insert(list, s:gsub(...))` correct, since `gsub`
returns a count as its second value that `table.insert` would read as an index.

Never write a multi-line `---@type` table shape. It is re-indented differently
on each `luafmt` pass, which surfaces as "formatting is not idempotent" rather
than as anything pointing at the annotation. Declare a `---@class` with one
`---@field` per line.

`---@diagnostic disable-next-line: <rule>` is the escape hatch for what LuaLS is
right to flag but which cannot be written around, for instance
`duplicate-set-field` when a test stubs `vim.notify`. Reach for it last.

Annotate every export. `scripts/luals_untyped.lua` fails if LuaLS cannot infer
anything more specific than `any` or `unknown` anywhere under `lua/`, so
coverage here is enforced rather than aspirational, and
`lua-language-server --check=.` runs at `Warning` with `luadoc`, `strict`,
`strong` and `type-check` all at `Any`, so annotation drift fails the gate and
not just genuine type errors.

Class naming is currently inconsistent, `cgxx.`-prefixed in some modules and
`util.`-prefixed in others. Follow the file you are in rather than converting
it.

The editor's live diagnostics are not the gate. A cold or mid-indexing LuaLS
reports spurious `undefined-global` on `vim` and `undefined-doc-name` on real
types; confirm against the repo-wide run before acting.

`lua/util/spec.lua` is superseded by `lua/plugin.lua`'s import groups and
required by nothing. Do not build on it.
