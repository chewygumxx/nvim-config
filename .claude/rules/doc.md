---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/rules/doc.md
  #
  #

ctime: 2026-09-27
title: Generated help tree
paths:
  - "doc/**/*"
tags:
  - llm
  - claude
---

# `doc/` is generated

`doc/` is this repository's own `:help`, rendered by `scripts/genhelp.lua` and
never edited by hand.

The generator deletes the whole tree and recreates it, so an edit here would
vanish on the next run with nothing reported. Change the source it is rendered
from, then regenerate:

```sh
nvim --headless -u scripts/minimal_init.lua -l scripts/genhelp.lua
```

Verify with `git status --porcelain -- doc/` rather than a diff.

This tree holds `.txt`, so the Markdown reflow hook does not touch it and a hand
edit survives the write to die silently at the next run.
`.claude/hooks/block-generated.sh` refuses the write instead. The
**`generated-output` skill** holds the rest.
