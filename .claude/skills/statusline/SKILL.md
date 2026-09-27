---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/skills/statusline/SKILL.md
  #
  #

ctime: 2026-09-27
title: Statusline
name: statusline
description: >-
  Work on this configuration's repository-notation statusline. Use when editing
  lua/util/statusline.lua, the CgxxStatusline highlight groups in
  lua/highlight.lua, the 'statusline' option in lua/option/view.lua, or
  tests/test_util_statusline.lua, and when the statusline renders wrongly,
  flickers, hangs or shows the wrong colours.
tags:
  - llm
  - claude
---

# Statusline

`option.view.setup()` installs a 'statusline' that replaces Neovim's default
leading `%f` with the same repository notation this config writes into file
headers, ie. `~chewygumxx/nvim-config.git:main:/lua/util/statusline.lua`.

`M.value()` reads the option's _default_, never its live value, which is what
makes it idempotent, and splices `M.items` over the `%<%f` it finds. The rest of
that default survives untouched: terminal exit code, LSP progress, `showcmd`,
`b:keymap_name`, the busy spinner, `vim.diagnostic.status()` and the ruler.

## Three load-bearing decisions

Each has a test that fails if it is undone.

**The segment is a plain `%{}` and never the nested `%{%...%}` form.** Only the
latter re-parses its result for statusline items, and it would mangle any `%` in
a filename.

**The fallback is a second item emitting the literal string `%f`** for Neovim to
expand, rather than this module reproducing it. `%f` is not `nvim_buf_get_name`:
it also supplies the bracketed names of special buffers and shortens against
`$HOME` and the cwd.

**Nothing in the render path calls git.** `M.segment` is a cache read; a miss
schedules one async `util.git.info` call and falls back to `%f` for that redraw.
`store` gates its `redrawstatus!` on the value actually changing, since
redrawing unconditionally turns any buffer appearing mid-redraw into a livelock.

## Why three items rather than one

The notation is coloured a part at a time, by `CgxxStatuslineSlug`,
`CgxxStatuslineBranch` and `CgxxStatuslinePath` from `lua/highlight.lua`. A
`%#Group#` only takes effect where the statusline is parsed for items, so
colouring from inside a value would mean the `%{%...%}` form and the mangling
above. Instead the highlight items sit in the format string _between_ the three
calls, and every value stays unparsed.

Each separator travels with the part before it rather than being written into
the format string, since a separator there would render beside the `%f` fallback
too.

The cache stays a single string that `split` slices left to right on `:`. That
is sound because git forbids `:` in a ref name and a slug cannot hold one, so
the first two colons are structural; a value that is not the notation at all,
ie. the `:~` filename used for a file outside any repository, which may hold a
colon anywhere, is left whole as the path. **Caching a table instead would break
`store`'s livelock guard**, since a table read back from `vim.b` never compares
equal to the one written.

The items close with `%*` and not `%#StatusLine#`, so an inactive window's
statusline returns to `StatusLineNC`. The highlight groups set a foreground
only, for the same reason.

## Invalidation

Filling is lazy on cache miss rather than on `BufEnter`, so a buffer displayed
by any route at all fills itself in. That leaves `M.autocmd()` responsible only
for invalidation: `BufFilePost`/`BufWritePost` per buffer,
`FocusGained`/`VimResume`/`ShellCmdPost`/`TermClose` for every buffer, which
covers a checkout made elsewhere, and `BufDelete`/`BufWipeout` to release the
in-flight marker.

That marker is a module-local table rather than a `vim.b` variable, because
`M.segment` runs during statusline evaluation and has no business mutating
buffer state. It also carries the buffer _name_ the in-flight call was issued
for, which is how a late answer recognises that a rename or a refresh has
superseded it.

## Testing

`tests/test_util_statusline.lua` asserts the runs from `nvim_eval_statusline`'s
`highlights`, ie. that the right group covers the right byte range. It defines
the three groups itself, because `test_highlight.lua` restores them to undefined
before it runs and `nvim_eval_statusline` reports an undefined group as the
statusline's own.

Two things it cannot reach, listed under "Behaviours no gate covers" in
`.claude/CLAUDE.md`: whether the palette is legible against the colorscheme, and
truncation shortening from the left, which is a property of `%<`'s position that
only shows in a narrow window. Re-check both by hand after touching either.
