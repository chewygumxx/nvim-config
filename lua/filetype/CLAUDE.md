---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/lua/filetype/CLAUDE.md
  #
  #

ctime: 2026-09-27
title: CLAUDE.md
description: >-
  Conventions for the per-filetype modules, most of which follow from the
  dispatcher running exactly one module per filetype.
tags:
  - llm
  - claude
---

# CLAUDE.md

`init.lua` holds two tables doing different jobs, and a change usually wants one
rather than both. `M.filetypes` is _detection_, the patterns Neovim does not
recognise out of the box, registered through `vim.filetype.add()` by
`M.setup()`; eg. `*.service` and `*.conf` to `dosini`, `ignore` and
`.chezmoiignore` to `gitignore`, the gnupg, hypr and zsh paths to `gpg`,
`hyprlang` and `zsh`. `M.modmap` is _dispatch_, mapping an already-detected
filetype to a module here, off the `FileType` autocmd `M.autocmd()` registers.
Several real filetypes may route to one module, which is why `dosini`,
`confini`, `gitconfig`, `cfg` and `editorconfig` all reach `dosini.lua`. A
filetype named in `M.modmap` with no module behind it notifies at `ERROR` rather
than failing quietly, so a typo there is heard about at the first buffer of that
type.

Write a module declaratively and add `M.setup` only when there is logic beyond
the declaration. `M.config` reads `M.local_opts` and applies each through
`vim.opt_local`, and reads `M.hlgroup_defs` and applies each once per session,
tracked by `highlights_defined` on the module itself. The contract is the
`cgxx.filetype.Module` class in `init.lua`, and every field on it is optional: a
module that is nothing but a table of highlight links is complete. `help.lua` is
the case that earns an `M.setup`, since repositioning the help window is not
expressible as an option.

**The dispatcher runs exactly one module per filetype, and everything awkward
here follows from that.** A compound filetype cannot inherit Markdown's
behaviour by being Markdown, so `nex_note.lua` aliases `markdown.setup` outright
and `claude.lua` calls it before its own work; adding to `markdown.setup` is
therefore what reaches all three, and adding to `claude.lua` reaches one. The
same rule cost `prose.lua` its `spell` setting when `gitcommit` arrived: a
`gitcommit` buffer runs `gitcommit.lua` and never `prose.lua`, so that option
had to be copied rather than inherited. Check what a filetype displaces before
assuming it composes.

`gitcommit.lua` takes both `gitcommit` and `gitrebase` and parses nothing,
deliberately. `tree-sitter-gitcommit` and `tree-sitter-git-rebase` are both in
`lua/spec/nvim-treesitter.lua`'s `ensure_installed`, and those grammars already
yield `(prefix (type))`, `(prefix (scope))`, the surrounding punctuation, the
`!` breaking marker, `(subject)`, `(trailer (token))` and
`(breaking_change (token))`, so the module is a `hlgroup_defs` table over those
captures: `@keyword.gitcommit` for the Conventional Commit type,
`@variable.parameter.gitcommit` for the scope, and so on. Anything that looks
like it needs parsing here probably wants a capture instead.

The 50 character header cap is shown with 'colorcolumn' (`51,73`, the second
being git's own body width) and deliberately not with the bundled syntax's
`gitcommitOverflow`, which exists for exactly this and cannot be seen in this
configuration: `vim.treesitter.start` draws above Vim syntax, and the grammar
captures the whole `(subject)` node including the overflow, so the syntax group
never gets a look in. Do not reach for it again on the assumption it was
overlooked.

`tests/test_filetype_modules.lua` drives every module here through
`filetype.config`, the real dispatcher, rather than calling a module directly,
so a module that declares the right options but is unreachable from `M.modmap`
still fails. Whether `colorcolumn=51,73` lands where git's limits actually are
is not something a headless run can see, and `.claude/CLAUDE.md` records it
among the behaviours no gate covers.
