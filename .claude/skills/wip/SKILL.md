---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/skills/wip/SKILL.md
  #
  #

ctime: 2026-09-27
title: WIP snapshots
name: wip
description: >-
  Work on or recover from the WIP snapshot system that commits unsaved buffer
  text onto refs/wip. Use when editing lua/util/wip.lua or
  tests/test_util_wip.lua, when the XXWip user command misbehaves, when refs/wip
  has grown or needs pruning, or when recovering buffer text lost to a crash.
tags:
  - llm
  - claude
---

# WIP snapshots

`lua/util/wip.lua` periodically commits the in-memory text of a tracked buffer
onto `refs/wip/<branch>`, so unsaved work survives a crash without any of it
becoming visible repository state.

## How a snapshot is taken

Git plumbing only, from one POSIX `sh` script run through a single async
`vim.system` call with the buffer serialised onto stdin. `hash-object -w` writes
the blob; a throwaway `GIT_INDEX_FILE` under the git dir then absorbs
`read-tree` + `update-index --cacheinfo` + `write-tree`; `commit-tree` +
`update-ref` move the ref.

HEAD, the real index and the working tree are never written, so `git status`
stays quiet and anything already staged survives. `refs/wip/*` sits outside
`refs/heads/*`, which keeps it invisible to `git branch`, `git log` and
`git push` while still counting as a gc root.

`commit-tree` bypasses the husky hooks by construction. Signing is forced off
via `-c commit.gpgsign=false`, because a gpg passphrase prompt has nowhere to go
from an async `vim.system` call and would hang the snapshot.

## When

Debounced (`M.debounce`, 2000 ms) off `TextChanged`/`TextChangedI`, and taken
immediately on `BufWritePost`/`BufLeave`/`FocusLost`. One whose tree matches the
ref tip exits before `commit-tree`, which is what makes those extra checkpoints
nearly free.

Eligibility is "inside a worktree and known to `git ls-files --error-unmatch`",
cached per buffer in `vim.b.cgxx_wip_location` and invalidated on `BufWritePost`
so a newly tracked file starts snapshotting.

`vim.g.cgxx_wip` and `vim.b.cgxx_wip` are the off switches. `XXWip` takes
`toggle`/`enable`/`disable`/`snapshot` plus a bang-only `drop`.

## Recovery

Plain git:

```sh
git log refs/wip/<branch>
git show refs/wip/<branch>:<path>
git restore --source=refs/wip/<branch> -- <path>
```

Nothing prunes the ref, so it grows until `XXWip! drop`. It is not pushed or
fetched without an explicit `refs/wip/*` refspec.

## Testing

`tests/test_util_wip.lua` builds real repositories under `vim.fn.tempname()`
with `helpers.repo()` and deletes them in `after_each`. That helper pins
everything git would otherwise take from the machine: the branch, since
`init.defaultBranch` is not something a test should inherit, and
`user.name`/`user.email` per repository, since a CI runner has no global
identity and `git commit` fails outright without one.

A case about a snapshot **not** happening waits for a fence rather than
sleeping. `M.snapshot`'s `report` argument makes it announce the no-op it
reached, which replaced three fixed `vim.wait(2000, ...)` sleeps that were half
the suite's runtime. Keep that shape when adding a case of the same kind.
