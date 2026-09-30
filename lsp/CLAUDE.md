---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/lsp/CLAUDE.md
  #
  #

ctime: 2026-09-27
title: CLAUDE.md
description: >-
  Conventions for the per-server LSP configuration tables Neovim discovers on
  the runtimepath.
tags:
  - llm
  - claude
---

# CLAUDE.md

This directory is Neovim's own runtimepath convention, not a directory this
configuration invents: `vim.lsp.enable()` resolves `lsp/<name>.lua` by the
server's name, so the filename is load-bearing. Carry `---@type vim.lsp.Config`
on `local M` and close with `return M`.

This uses the **native** `vim.lsp.config`/`vim.lsp.enable` mechanism, so do not
reach for `nvim-lspconfig`'s old `setup{}` API even where a tutorial shows it.

**Each file is the whole configuration for its server.** `nvim-lspconfig` is
condemned in `lua/plugin.lua`, so nothing merges in what a file leaves out: give
every server its `cmd`, `filetypes`, and `root_markers` or a `root_dir`.
`tests/test_spec.lua` fails a file missing any of them. Do not bring the plugin
back as a source of defaults. Its own `lsp/<name>.lua` sits later on the
runtimepath than ours, so it silently won every key both set; that is how
`shuck` attached to bash buffers against its own `filetypes = { "zsh" }` and
`markdown_oxide` ran a binary name its file did not give. When porting a
server's upstream config, carry its values over and write its functions afresh
rather than `require("lspconfig.util")`, which would load nothing.

`util.lsp.setup`, called from `init.lua`, enables exactly the servers this
directory holds, and evaluates every file here at startup to do so. A file that
cannot load therefore takes the session down rather than one filetype, so an
optional plugin such as schemastore is `pcall`ed, and the suite evaluates every
file with no module allowed to be missing. mason-lspconfig only installs:
`automatic_enable` reached only what Mason had installed, which under Termux was
nothing.

Everything shared lives in `lua/util/lsp.lua`: blink.cmp's capabilities over
Neovim's defaults, `vim.diagnostic.config()`, the buffer-local keymaps on every
`LspAttach`, and three helpers several servers here need. `node_cmd` prefers a
project's own `node_modules/.bin` binary; pair it with `node_available` in the
server's `root_dir`, since Neovim checks only a _table_ `cmd` for an executable
and a function that cannot start one errors on every buffer it matches. `js_root`
is the lockfile-then-`.git` root the JavaScript servers share, declining Deno
projects. A per-server file that repeats any of that is a second opinion waiting
to drift.

`eslint`, `biome` and the conform spec all read the same evidence through
`lua/util/biome.lua`, so they cannot disagree about a buffer. A repository that
configures both eslint and Biome gets both, which is what it asked for.

A new file here is not self-sufficient. `tests/test_spec.lua` asserts that
`lua/spec/mason-lspconfig.nvim.lua`'s `ensure_installed` holds _exactly_ the
servers this directory configures, so adding a server without adding it there
fails the suite, and so does the reverse. Under Termux the whole mason trio is
condemned from `lua/plugin.lua`, and `mise.toml` is where those same servers
come from instead, so a server added here should be reachable by both routes.
