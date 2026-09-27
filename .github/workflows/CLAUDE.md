---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.github/workflows/CLAUDE.md
  #
  #

ctime: 2026-09-26
title: CLAUDE.md
description: >-
  The one repository-wide rule the GitHub Actions workflows have to hold to.
tags:
  - llm
  - claude
---

# CLAUDE.md

Ensure that any workflow within this repository that utilises Node.js employ
version 24 or later.

Name a tool version in `mise.toml` and nowhere else. A job needing one reads it
through `.github/scripts/tool_version.py`, which exits non-zero on a key it does
not know, so a workflow cannot quietly fall back to whatever the runner happened
to ship. A version restated in an `env:` block or inlined into a download URL is
a second pin that will disagree with the first, and the one a contributor's
`PATH` supplies is the one that decides whether the gate meant anything.

Any step running a script under `scripts/minimal_init.lua` must install
mini.test first, via `./.github/actions/install-mini-test`. That bootstrap
raises when mini.test is absent, but it is passed as `-u`, so the raise is a
startup error: Neovim reports it and carries on without ever reaching its
`runtimepath` assignment. The job therefore goes green over a gate that never
really ran, which is what happened to `LuaCATS` between the commit that added
its annotation-coverage step and the one that fixed it.
