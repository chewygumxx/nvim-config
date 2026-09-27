---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.github/CLAUDE.md
  #
  #

ctime: 2026-09-27
title: CLAUDE.md
description: >-
  Rules for the workflows, the composite actions and the scripts they share,
  including the two ways a job here can go green over a gate that never ran.
tags:
  - llm
  - claude
---

# CLAUDE.md

Filed one level above `workflows/` on purpose, since most of what follows is
about `actions/` and `scripts/` as much as about a workflow file.

Ensure that any workflow within this repository that utilises Node.js employ
version 24 or later.

**Name a tool version in `mise.toml` and nowhere else.** A job needing one reads
it through `.github/scripts/tool_version.py`, which exits non-zero on a key it
does not know, so a workflow cannot quietly fall back to whatever the runner
happened to ship. A version restated in an `env:` block or inlined into a
download URL is a second pin that will disagree with the first, and the one a
contributor's `PATH` supplies is the one that decides whether the gate meant
anything. That script prints in two shapes: a bare tool key prints the version
alone, for `$(...)` capture, and `NAME=key` pairs print `NAME=version`, for
appending straight to `$GITHUB_ENV`. It is Python over `tomllib` rather than a
regex because a `[tools]` entry is either a bare version string or a table
carrying `matching` beside `version`, and the keys themselves contain the `:`
and `/` that make them awkward regex subjects.

**Any step running a script under `scripts/minimal_init.lua` must install
mini.test first**, via `./.github/actions/install-mini-test`. That bootstrap
raises when mini.test is absent, but it is passed as `-u`, so the raise is a
startup error: Neovim reports it and carries on without ever reaching its
`runtimepath` assignment. The job therefore goes green over a gate that never
really ran, which is what happened to `LuaCATS` between the commit that added
its annotation-coverage step and the one that fixed it.

Three composite actions exist and each pins rather than tracks. `setup-neovim`
installs, caches and PATHs the release `mise.toml` pins, reading it through
`tool_version.py`; pass `version: nightly` for the canary, which is deliberately
never cached. `install-lazy` clones the lazy.nvim commit `lazy-lock.json` pins,
fetching that sha directly rather than cloning a branch, and caches on the
commit. `install-mini-test` reads the tag `lua/spec/mini.test.lua` names and
asks Neovim for `stdpath("data")` rather than assuming it.

`install-mini-test` resolves that tag to a commit with
`git ls-remote <url> "refs/tags/<tag>^{}"` before fetching, rather than cloning
the ref, and that indirection is load-bearing: these tags are annotated, so
`refs/tags/v0.18.0` names a tag object and not the commit it points at, and
`git clone --depth 1 --branch` of such a ref makes git print
`warning: ... is not a commit!` on every run. The checkout and working tree were
correct either way, but the warning is indistinguishable at a glance from a real
failure. Resolving first also makes a tag absent upstream fail with a message
naming it. Nothing reads the installed copy's git metadata, so the absent tag
ref costs nothing, which was checked by running the suite against a copy
carrying no tags.

`workflows/test.yaml` runs the suite from one matrix, once on the pinned release
and once on nightly with `continue-on-error`, so an upstream change is heard
about before it reaches a release and is not reported as the fault of whichever
pull request ran next. Keep a new canary job inside that matrix rather than
beside it.
