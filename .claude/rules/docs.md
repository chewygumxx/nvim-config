---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/rules/docs.md
  #
  #

ctime: 2026-09-27
title: Generated LuaCATS reference
paths:
  - "docs/**/*"
tags:
  - llm
  - claude
---

# `docs/` is generated

`docs/` is the browsable LuaCATS reference, rendered by `scripts/gendoc.lua`
from the annotations under `lua/`, and never edited by hand.

The generator deletes the whole tree and recreates it, so an edit here would
vanish on the next run with nothing reported. Change the annotation it is
rendered from, then regenerate:

```sh
nvim --headless -u scripts/minimal_init.lua -l scripts/gendoc.lua
```

Verify with `git status --porcelain -- docs/` rather than a diff.

`.claude/hooks/block-generated.sh` refuses the write outright, and the Markdown
reflow hook would corrupt a page here besides. The **`generated-output` skill**
holds the rest.
