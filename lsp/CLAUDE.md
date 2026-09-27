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

Add only what is genuinely server-specific: `root_markers`, extra
`capabilities`, an `on_attach` for highlight groups. Everything shared already
exists in `lua/util/lsp.lua`, which merges blink.cmp's completion capabilities
over Neovim's defaults, calls `vim.diagnostic.config()`, and wires the
buffer-local keymaps on every `LspAttach`. A per-server file that repeats any of
that is a second opinion waiting to drift.

A new file here is not self-sufficient. `tests/test_spec.lua` asserts that
`lua/spec/mason-lspconfig.nvim.lua`'s `ensure_installed` holds _exactly_ the
servers this directory configures, so adding a server without adding it there
fails the suite, and so does the reverse. Under Termux the whole mason trio is
condemned from `lua/plugin.lua`, and `mise.toml` is where those same servers
come from instead, so a server added here should be reachable by both routes.
