---
ctime: 2026-09-27
mtime: 2026-10-05
spdx: GPL-3.0-only
title: Repository metadata
paths:
  - ".repo-metadata.jsonc"
tags:
  - llm
  - claude
---

<!--
   -
   - ~chewygumxx/nvim-config.git
   - ::: :/.claude/rules/repo-metadata.md
   -
   -->

# `.repo-metadata.jsonc` is the GitHub settings page

This file holds the GitHub repository's own description, topics and licence. The
`sync-repo-metadata` Action applies it whenever it changes, so those settings
are edited here and not in the web interface.

Editing them in the web interface is the failure worth naming: nothing rejects
it, and the next push silently reverts it.

<!-- vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3: -->
