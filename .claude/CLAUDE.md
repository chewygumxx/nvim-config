---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/CLAUDE.md
  #
  #

ctime: 2026-09-26
title: CLAUDE.md
description: >-
  The long-form reference for this configuration: why each decision is the way
  it is, and what a given change is likely to break.
tags:
  - llm
  - claude
---

# CLAUDE.md

Absolutely no em dashes are to be employed within this repository.

Ensure any printed conversation output line length is limited to 80 characters
except where it may be unfeasable to do so eg. URL.

For all work performed in this repository, please compose single-line commit
messages for granular commits and continuously commit as you work.

## What this repository is

`chewygumxx/nvim-config`: a standalone Neovim configuration, plugin-managed by
[lazy.nvim](https://lazy.folke.io), with its own git history and CI.

Anything that is a fact about the code belongs in `README.md` or a doc comment.
Anything that is a reason belongs in the narrowest file that can hold it,
because that is the one that loads only when it matters. **This file is loaded
into every session and every subagent regardless of relevance, so it holds only
what is repository-wide and has nowhere narrower to go.** A new reason almost
never belongs here; `tests/test_claude_assets.lua` caps its length to make that
mechanical rather than advisory.

## Where the reasons live

| Subject                                                    | Where                                              |
| ---------------------------------------------------------- | -------------------------------------------------- |
| Lint, format, typecheck and test gates; tool pins; CI jobs | **`gates` skill**                                  |
| `doc/` and `docs/`, and the two generators that own them   | **`generated-output` skill**                       |
| Plugins, specs, `lua/plugin.lua`, `lazy-lock.json`         | **`specs` skill** and `lua/spec/CLAUDE.md`         |
| Anything under `.claude/`: skills, commands, rules, hooks  | **`claude-assets` skill**                          |
| The repository-notation statusline                         | **`statusline` skill**                             |
| WIP snapshots onto `refs/wip`                              | **`wip` skill**                                    |
| Markdown list continuation and the Markdown keymaps        | **`markdown-continuation` skill**                  |
| Workflows, composite actions, how a job reads a pin        | `.github/CLAUDE.md`                                |
| Filetype detection and dispatch                            | `lua/filetype/CLAUDE.md`                           |
| What belongs in a per-server file                          | `lsp/CLAUDE.md`                                    |
| The shared helpers and their annotation habits             | `lua/util/CLAUDE.md`                               |
| Writing a test, and what the registry files police         | `tests/CLAUDE.md`                                  |
| Tree-sitter queries and their layout                       | `queries/CLAUDE.md`                                |
| `scripts/`, `types/`, `snippets/`, `.repo-metadata.jsonc`  | a rule in `.claude/rules/`, loaded on a read there |

`README.md` holds the directory layout, the requirements and the gate commands.
The skills load when their subsystem is touched; the directory files load on a
read in their directory; the rules load on a read of a path they scope. None of
them costs anything until then, which is why they are the right destination and
this file is not.

## Architecture

`init.lua` calls `require(modpath).setup()` per top-level module, in an order
documented inline there. Machine- and environment-specific choices, ie.
colourscheme, fuzzy finder and the Herdr and Termux checks, are made at the
point of use rather than through an indirection layer.

Language servers use Neovim's **native** `vim.lsp.config` and `vim.lsp.enable`,
one table per server in `lsp/` and everything shared in `lua/util/lsp.lua`,
never `nvim-lspconfig`'s old `setup{}` API. This is worth stating here because a
new server file can be written without reading an existing one, which is the one
route that reaches no narrower file.

## Conventions

- **File headers**: nearly every tracked file opens with an editor modeline, an
  `SPDX-License-Identifier: GPL-3.0-only` line and a boxed comment giving the
  repository slug and the file's repo-relative path, in that file's line-comment
  syntax. Follow a sibling of the same type rather than inventing one;
  `XXInsertHeader` generates one, and the `sync-header-metadata` Action corrects
  drift. Markdown wears the same three parts as a `__cgxx: |` block inside the
  frontmatter, rendered by `util.header.frontmatter`, which is the only
  description of that shape: copy a sibling or call it rather than assembling
  one by hand.
- **Indentation**: owned by `.editorconfig`, 4 spaces except 2 for `*.md` and
  `*.scm`, and Lua additionally by `luafmt`'s `max_line_width = 80`.
- **Lua annotations vs. `luafmt`**: two habits exist because the formatter will
  otherwise silently undo the annotation. `lua/util/CLAUDE.md` states both with
  their reasons, and they apply to Lua anywhere in the repository, not only
  under `lua/util/`.
- **Commit messages**: Conventional Commits, enforced by commitlint and husky.
  Scope is optional and several can be joined with `/`, but nothing outside
  `.commitlintrc.mts`'s `scope.enum` is accepted, **including a type name**:
  `docs(ci)` is rejected, since `ci` is a type rather than a scope.
  `header-max-length` caps the whole `type(scope): Subject` header at 50
  characters, so keep subjects short.
- **No AI co-author trailers**: do not add a `Co-Authored-By: Claude ...` (or
  similar) trailer unless explicitly asked to, on that specific commit.

## Behaviours no gate covers

Four things are asserted only as far as a headless process can reach, so a
regression in them is silent and has to be looked at. All four were confirmed by
hand in a live Neovim on 2026-09-27, which is what makes them a baseline rather
than an open question; re-check the relevant one after touching it.

They are the statusline's colours and its truncation from the left, the
`gitcommit` header overflow, `<leader>.` returning the same scratch buffer after
a restart, and which-key's group labels. Each is described where it belongs: the
**`statusline` skill**, `lua/filetype/CLAUDE.md`, the **`specs` skill** and the
**`generated-output` skill** respectively.
