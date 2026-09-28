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
  Rules for the workflows and the composite actions they share, including how a
  job installs a pinned tool and how one can go green over a gate that never
  ran.
tags:
  - llm
  - claude
---

# CLAUDE.md

Filed one level above `workflows/` on purpose, since most of what follows is
about `actions/` as much as about a workflow file.

Ensure that any workflow within this repository that utilises Node.js employ
version 24 or later.

**Name a tool version in `mise.toml` and nowhere else.** A job needing one
installs it with `jdx/mise-action`, passing the `[tools]` keys it runs as
`install_args`, so the version is whatever `mise.toml` says and a workflow
cannot quietly fall back to whatever the runner happened to ship. A version
restated in an `env:` block, inlined into a download URL or handed to a
`setup-*` action is a second pin that will disagree with the first, and the one
a contributor's `PATH` supplies is the one that decides whether the gate meant
anything. Node is no exception: it is installed by mise, not `setup-node`.

Always pass `install_args`. `mise.toml` pins the whole editor toolchain beside
the gates, and a bare `mise install` would fetch all of it, `pipx:` and `npm:`
backends included, for a job that runs one binary. The action caches on a hash
of `mise.toml` and of those arguments, so a bump is a cache miss rather than a
stale binary, and each job's cache holds only its own tools. A shim runs only
the tool it names and does not install the rest of `mise.toml` on the way,
which was checked by installing one tool and running its shim. Name an aliased
tool by its alias, eg. `luafmt`, since that is the `[tools]` key.

**Any step running a script under `scripts/minimal_init.lua` must install
mini.test first**, via `./.github/actions/install-mini-test`. That bootstrap
raises when mini.test is absent, but it is passed as `-u`, so the raise is a
startup error: Neovim reports it and carries on without ever reaching its
`runtimepath` assignment. The job therefore goes green over a gate that never
really ran, which is what happened to `LuaCATS` between the commit that added
its annotation-coverage step and the one that fixed it.

Three composite actions exist. `setup-neovim-nightly` installs the nightly
build for the canary, and is deliberately never cached; the pinned release is
installed by mise like any other tool, and nightly is not a pin, so it has no
`mise.toml` entry to read. `install-lazy` clones the lazy.nvim commit
`lazy-lock.json` pins, fetching that sha directly rather than cloning a branch,
and caches on the commit. `install-mini-test` reads the tag
`lua/spec/mini.test.lua` names and asks Neovim for `stdpath("data")` rather than
assuming it.

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
beside it. Only the pinned leg runs `jdx/mise-action`, so on the nightly leg no
shim for the pinned release sits on `PATH` beside the canary.
