---
ctime: 2026-09-27
mtime: 2026-10-05
spdx: GPL-3.0-only
title: Snippet manifest
paths:
  - "snippets/**/*"
tags:
  - llm
  - claude
---

<!--
   -
   - ~chewygumxx/nvim-config.git
   - ::: :/.claude/rules/snippets.md
   -
   -->

# `snippets/` is not currently reached at runtime

A friendly-snippets-style manifest plus per-language JSON, in the shape LuaSnip
loads.

LuaSnip is **elided** in `lua/plugin.lua`, so its spec loads and the plugin does
not. Nothing here takes effect in a running Neovim until that changes, which
means an edit cannot be confirmed by trying the snippet: check the JSON against
the manifest instead.

The **`specs` skill** holds what elision is and the single place it survives
lazy.nvim's merge.

<!-- vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3: -->
