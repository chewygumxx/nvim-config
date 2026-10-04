---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/skills/markdown-continuation/SKILL.md
  #
  #

ctime: 2026-09-27
title: Markdown list continuation
name: markdown-continuation
description: >-
  Work on Markdown list continuation and the buffer-local Markdown keymaps. Use
  when editing lua/util/markdown_list.lua, lua/util/markdown_table.lua,
  lua/filetype/markdown.lua, lua/filetype/nex_note.lua or
  lua/filetype/agentprompt.lua, when o/O or <M-CR> behaves wrongly in a Markdown
  buffer, or when a completion key stops working there.
tags:
  - llm
  - claude
---

# Markdown list continuation

## Why this is Lua and not 'comments'

Neovim will not continue a Markdown list, and not by omission.
`$VIMRUNTIME/ftplugin/markdown.vim` sets `formatoptions-=r formatoptions-=o`,
removing the two flags that repeat a comment leader on `<CR>` and on `o`/`O`.

Restoring them would not be enough either. The leaders it defines are
`comments=fb:*,fb:-,fb:+,n:>`, and the `f` flag means "only the first line
carries the leader", so `o` yields a bare indent rather than a new bullet.
`comments` also has no way to express `- [ ] ` rather than `- `, or to turn `1.`
into `2.`.

So the continuation is computed instead. `M.parse` recognises bullet, ordered
(`.` and `)`), checkbox, ordered-checkbox and blockquote forms, and `M.sibling`
builds the next prefix, advancing an ordered marker and always continuing a
checkbox as unchecked.

Two behaviours are deliberate: nothing renumbers the rest of a list, and an item
with no content ends the list rather than adding another empty marker.

## Why not `<CR>`

Bound to `o`/`O` in normal mode and `<M-CR>` in insert, and deliberately **not**
to `<CR>`.

`lua/spec/blink.cmp.lua` maps `<CR>` to `{ "accept", "fallback" }`, and a
buffer-local mapping outranks a global one. Taking `<CR>` here would stop Enter
accepting a completion in exactly the filetype where word and link completion is
used most.

`o`/`O` fall back by feeding themselves with remapping off when the cursor is
not on a list item, so a non-list line behaves exactly as it would unmapped.

## Reaching the compound filetypes

`lua/filetype/markdown.lua`'s `M.setup` attaches two sets of buffer-local
keymaps, from `util.markdown_table` and `util.markdown_list`.

The filetype dispatcher runs exactly one module per filetype, so the compound
Markdown filetypes cannot inherit that by being Markdown. `filetype.nex_note`
aliases `markdown.setup` outright, and `filetype.agentprompt` calls it before
its own work. **Adding to `markdown.setup` is therefore what covers all three**;
adding a mapping anywhere else covers only plain Markdown.

## `gq`, auto-wrap and the hanging indent

The indent under a wrapped list item, two columns under `- ` and six under
`- [ ] `, is not computed: it is `n` in 'formatoptions' reading
'formatlistpat', which `filetype.markdown` widens to recognise a checkbox. That
only works because `comments` is trimmed to `n:>`. The ftplugin's `fb:-` and its
siblings make a bullet a comment leader, and a comment leader outranks
'formatlistpat' and always hangs by two columns.

`util.markdown_format` is the 'formatexpr'. It hands `gq` to the internal
formatter one prose run at a time, skipping fences, frontmatter, HTML blocks and
pipe tables, and declines auto-wrap on a line inside one. Tree-sitter finds the
blocks; a line scan stands in for frontmatter and fences when it cannot parse.
