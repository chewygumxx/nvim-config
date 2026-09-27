---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/queries/CLAUDE.md
  #
  #

ctime: 2026-09-27
title: CLAUDE.md
description: >-
  Conventions for the Tree-sitter queries, every one of which replaces the
  runtime query rather than extending it.
tags:
  - llm
  - claude
---

# CLAUDE.md

**No file here carries an `; extends` comment, so each one fully replaces the
runtime query for its language rather than adding to it.** That is a decision,
not an oversight, and it means anything the bundled query provided has to be
reproduced. `queries/comment/highlights.scm` does exactly that, copying
nvim-treesitter's own captures with the provenance URL inline; deleting them
because they look redundant removes highlighting. `tests/test_queries.lua`
records the `extends` state per file in a registry, so changing it is a
deliberate edit there and not a silent one.

`queries/comment/highlights.scm` is this repository's own, highlighting the file
headers described under Conventions, and is the sole user of the three custom
predicates `lua/util/treesitter.lua` registers (`adjacent?`, `last-matching?`,
`header-line?`). Renaming or removing one breaks both this file and the parity
gate that asserts every predicate and directive resolves after
`util.treesitter.setup()` has run.

Validation reaches three depths, because the grammars these target are not all
available. Every file is parsed as the _query language_ using the `query`
grammar Neovim bundles, which needs none of the target parsers and so covers all
eight files. Predicates and directives are then checked for resolution. Finally
`vim.treesitter.query.parse` compiles a file against its own grammar, which
reaches only the languages Neovim ships a parser for; which those are is
registered rather than discovered, so a parser arriving or leaving is a failure
to read rather than a silent change in coverage.

When adding a predicate, note that `vim.treesitter.query.list_predicates()` and
`list_directives()` return names already carrying their `?` or `!`. Appending
one yields `eq??` and reports every core predicate as missing.

Copy the `set`-style modeline that `util.modeline.base` generates. Two files
still carry an older form, and two lack the SPDX line; both are the
bundled-query overrides and neither is a pattern to follow.

`norg` and `norg_meta` are dormant while neorg is condemned in `lua/plugin.lua`,
which is not the same as unchecked: the query-language parse and the predicate
parity gate still cover them.
