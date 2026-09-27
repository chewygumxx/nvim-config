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

**Do not hand-indent anything here.** `ts_query_ls format` owns the layout, the
`Queries` CI job runs it as `--check`, and `.husky/pre-commit` runs it as a
write. It indents at two spaces and offers no option to change that, which is
why `.editorconfig` has a `[*.scm]` block and the modelines all say
`shiftwidth=2`: they follow the formatter rather than the repository's usual 4.
It also collapses every blank line in a leading comment run, so the header box
here is contiguous where every other filetype separates the modeline, the SPDX
line and the box. Expect lines past 80 columns as well, since it will join a
wrapped predicate's arguments back onto one line and nothing caps the width of a
`.scm` file.

One surprise worth knowing before you debug a failing gate: a single `format`
pass is not a fixed point. Joining those predicate arguments is a change the
tool's own `--check` demands but that one write pass will not make, so
`.husky/pre-commit` runs it twice and then asserts with `--check`.

`ts_query_ls lint` is the linter, chosen over `check` because it needs no parser
objects and so reaches all eight files, where `check` would silently cover only
the languages Neovim bundles a parser for. It earned its place immediately: it
found five `(#set! conceal "")` patterns in
`queries/markdown_inline/highlights.scm` with no capture to attach to, which
Tree-sitter had been discarding without a word, so Markdown link concealment had
simply never worked. It does now, confirmed in a live buffer on 2026-09-27. The
repair was `@conceal`, matching the capture the working pattern above it already
uses, and deliberately **not** upstream's `@markup.link`: this file documents
having removed that in favour of the finer-grained `@markup.link.bracket`,
`.text`, `.title` and `.label` captures it declares at the top, so restoring it
would have undone deliberate work to fix an unrelated defect. Note `--fix`
**deletes** a pattern like this rather than giving it a capture, so read a fix
before taking it.

`.tsqueryrc.json` is almost empty on purpose. `valid_predicates` replaces the
tool's defaults rather than extending them, so declaring the three custom
predicates there would make every core `#eq?` an "unrecognized predicate".
Predicate parity stays where it already was, in `tests/test_queries.lua` against
`lua/util/treesitter.lua`.

Two files lack the SPDX line, and that is left alone rather than corrected: they
are the bundled-query overrides, largely copied from upstream, so asserting
`GPL-3.0-only` over them would be a licensing claim rather than a tidy-up.

`norg` and `norg_meta` are dormant while neorg is condemned in `lua/plugin.lua`,
which is not the same as unchecked: the query-language parse and the predicate
parity gate still cover them.
