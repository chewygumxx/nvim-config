---
ctime: 2026-10-05
mtime: 2026-10-05
spdx: GPL-3.0-only
title: Neovim and plugin help
name: nvim-help
description: >-
  Look up Neovim's or an installed plugin's documentation at the version
  actually on disk. Use before writing against a vim.* or vim.api function, a
  plugin's setup options or Lua API, an option, an autocommand event or a
  highlight group, and whenever unsure that one exists or what it takes in the
  Neovim mise pins or a plugin's checked-out commit.
tags:
  - llm
  - claude
---

<!--
   -
   - ~chewygumxx/nvim-config.git
   - ::: :/.claude/skills/nvim-help/SKILL.md
   -
   -->

# Neovim and plugin help

Training data describes Neovim and its plugins at whatever version they were
when it was written, and the web describes them at upstream HEAD. Neither is
what this configuration runs. `mise.toml` pins Neovim, and lazy.nvim has every
plugin checked out under `stdpath("data")` with its `:help` tags already built,
so the documentation for exactly what runs is on disk. Read it there.

## Look up a tag

```sh
. ./.claude/hooks/lib/tools.sh && mise_path
nvim --headless --clean -l .claude/skills/nvim-help/help.lua 'vim.lsp.enable()'
nvim --headless --clean -l .claude/skills/nvim-help/help.lua blink-cmp-config-keymap 120
```

It prints the help file and line it landed on, then 60 lines from the tag, or
as many as the second argument asks for. Source `tools.sh` first: without it the
`nvim` on `PATH` may not be the pinned one, and its runtime documents another
version.

**Read the tag line it prints.** `:help` falls back to its best guess when no
tag matches exactly, so a lookup can succeed and show something else. Exit 1
with `E149` means nothing matched at all.

Tags follow the usual `:help` shapes, ie. `vim.fs.joinpath()`,
`nvim_buf_set_extmark()`, `'statusline'`, `LspAttach`, `hl-NormalFloat`.
Plugins choose their own: `<plugin>-config-<key>` is common, and a plugin whose
help lazy.nvim generated from its README has tags of the form
`<plugin>-<heading>`, such as `claudecode.nvim-architecture`.

## Search when no tag is known

```sh
nvim --headless --clean -l .claude/skills/nvim-help/help.lua --paths
```

prints every `doc/` directory on the same runtimepath, Neovim's own first. Pass
them to `grep -rn`. A plugin's `doc/tags` file is the cheapest index of what it
documents.

## When the version matters

The checkouts under `stdpath("data")` are what the _deployed_ configuration
installed, and they can sit at a commit other than the one this checkout's
`lazy-lock.json` records. When a behaviour hinges on the exact version, compare
the two:

```sh
git -C ~/.local/share/nvim/lazy/fzf-lua rev-parse HEAD
jq -r '."fzf-lua".commit' lazy-lock.json
```

and if they differ, read the locked commit's documentation with
`git -C <checkout> show <commit>:doc/<file>.txt` rather than the working tree.

`nvim-lspconfig` still has documentation here, and it is still not a source of
defaults: `lua/plugin.lua` condemns it and every file in `lsp/` is a whole
configuration. Read its server pages for what a server expects, never for what
this configuration inherits.

<!-- vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3: -->
