---
ctime: 2026-09-27
mtime: 2026-10-05
spdx: GPL-3.0-only
title: LuaLS type stubs
paths:
  - "types/**/*"
tags:
  - llm
  - claude
---

<!--
   -
   - ~chewygumxx/nvim-config.git
   - ::: :/.claude/rules/types.md
   -
   -->

# `types/` stubs are load-bearing, and look redundant

These are `---@meta` declaration stubs for what LuaLS cannot see on its own.
Nothing requires them and nothing executes them, so their only reader is the
language server.

**Do not delete a stub because `workspace.library` appears to make it
redundant.** That appearance is exactly what a working stub produces: the symbol
resolves, so the stub looks like it is not doing anything. Removing one is only
visibly wrong later, in a typecheck run against a different workspace
configuration.

`.husky/pre-commit` holds `selene` back from this directory, because a stub's
intentional global declarations would otherwise read as real bugs. A lint that
suddenly fires here means the exclusion was lost, not that the stub is wrong.

<!-- vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3: -->
