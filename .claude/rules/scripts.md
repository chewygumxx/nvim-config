---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/rules/scripts.md
  #
  #

ctime: 2026-09-27
title: Headless entry points
paths:
  - "scripts/**/*"
tags:
  - llm
  - claude
---

# `scripts/` may not reach the network

Every script here runs headless, in CI as well as locally, and **none of them
may reach the network**. A script that fetches is a script that passes on a warm
machine and fails on a cold one, which makes a red CI run say nothing about the
change that triggered it.

`scripts/lazy_merge.lua` is the worked example rather than the exception. It
asserts lazy.nvim is already installed instead of letting `util.lazy.setup`
clone it, and it forces `install = { missing = false }` with `checker` and
`rocks` both disabled, because all three of those fetch. Anything new here that
touches plugin state owes the same three switches.

The **`gates` skill** holds what each script is for, except `scripts/gendoc.lua`
and `scripts/genhelp.lua`, which belong to the **`generated-output` skill**.
