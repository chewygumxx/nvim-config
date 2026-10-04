---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/skills/new-server/SKILL.md
  #
  #

ctime: 2026-10-05
title: New language server
name: new-server
description: >-
  Add a language server end to end: its lsp/ file, its mason install, its mise
  pin and the regenerated docs
argument-hint: <server-name> [filetype...]
disable-model-invocation: true
tags:
  - llm
  - claude
---

Add the language server `$ARGUMENTS` to this configuration. The first word is
the server's name, the rest are the filetypes it should attach to when they are
not obvious from the server.

Read `.claude/rules/lsp.md` before writing anything. It loads on a read under
`lsp/`, and a new file is the one route that reaches `lsp/` without reading
anything there, so here it has to be read by hand.

**The name is load-bearing.** `vim.lsp.enable()` resolves `lsp/<name>.lua` by
it, and `mason-lspconfig` installs by it, so use the name `nvim-lspconfig` gives
the server rather than its binary's name: `bashls`, not `bash-language-server`.

## 1. What the server expects

Use the `nvim-help` skill on `nvim-lspconfig`'s page for the server, for its
command, filetypes, root markers and any settings worth carrying. Carry values
over and write any function afresh: `nvim-lspconfig` is condemned and nothing
here may `require("lspconfig.util")`.

## 2. `lsp/<name>.lua`

Copy the header and shape of a sibling such as `lsp/bashls.lua`, or run
`XXInsertHeader`, then give the server its whole configuration:

- `---@type vim.lsp.Config` on `local M`, closing with `return M`
- `cmd`, `filetypes`, and `root_markers` or a `root_dir`; `tests/test_spec.lua`
  fails a file missing any of them, since nothing merges defaults in
- an optional plugin required by the file is `pcall`ed, because every file in
  `lsp/` is evaluated at startup and one that cannot load takes the session down

`util.lsp.setup` enables it with no further wiring.

## 3. `ensure_installed`

Add the name to `lua/spec/mason-lspconfig.nvim.lua`'s `ensure_installed`, under
its language's comment or a new one. `tests/test_spec.lua` asserts that list and
`lsp/` hold exactly the same servers, in both directions.

## 4. `mise.toml`

Pin the binary in the `[tools]` group for its language, with the backend named
explicitly (`npm:`, `github:`, `aqua:` or `pipx:`) and the current release. This
is what supplies the server under Termux, where mason is condemned. Check the
backend resolves before relying on it:

```sh
mise ls-remote <backend>:<package> | tail -3
```

## 5. Verify and regenerate

```sh
. ./.claude/hooks/lib/tools.sh && mise_path
MINITEST_PATTERN='^tests/test_spec%.lua ' \
    nvim --headless -u scripts/minimal_init.lua -l scripts/minitest.lua
```

Then `/regen`: `scripts/gendoc.lua` documents every file in `lsp/`, so `docs/`
gains a page for the server and the `Docs` CI job fails without it.

## 6. Commit

Granularly, scoped `lsp`, eg. `feat(lsp): Add <name>`, keeping the header under
50 characters. The regenerated `docs/` belongs in the same commit as the file
that changed it.
