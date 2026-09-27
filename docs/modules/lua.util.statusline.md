# global lua.util.statusline








---

## methods
---

### M.segment
---
```lua
function M.segment(bufnr: integer?) -> segment string
```
@param `bufnr` - Default: current buffer






'statusline' `%{}` callback: bufnr's cached git segment, or "" when
there is none to show yet. Pairs with `M.fallback`.

Evaluated in the context of the window being drawn, so the default of
the current buffer is that window's buffer.








### M.slug
---
```lua
function M.slug(bufnr: integer?) -> slug string
```
@param `bufnr` - Default: current buffer






'statusline' `%{}` callback: the repository part of bufnr's segment,
separator included, or "" when there is none. Pairs with `M.branch` and
`M.path`, which are the same read of the same cache.








### M.branch
---
```lua
function M.branch(bufnr: integer?) -> branch string
```
@param `bufnr` - Default: current buffer






'statusline' `%{}` callback: the branch part of bufnr's segment, or ""
when there is none.








### M.path
---
```lua
function M.path(bufnr: integer?) -> path string
```
@param `bufnr` - Default: current buffer






'statusline' `%{}` callback: the path part of bufnr's segment, or ""
when there is none. Carries the whole value for a file outside any
repository, which has neither of the other two parts.








### M.fallback
---
```lua
function M.fallback(bufnr: integer?) -> item string
```
@param `bufnr` - Default: current buffer


@return `item` - `"%f"`, or "" when a git segment is being shown





'statusline' `%{%...%}` callback: the literal `%f` item whenever
`M.segment` has nothing to show, so Neovim renders the filename itself.








### M.refresh
---
```lua
function M.refresh(bufnr: integer?) ->  nil
```
@param `bufnr` - Default: current buffer






Drops bufnr's cached segment, so the next redraw resolves it again.








### M.refresh_all
---
```lua
function M.refresh_all() ->  nil
```





Drops every loaded buffer's cached segment. For a change of git state
that is global rather than per-buffer, ie. a checkout.








### M.autocmd
---
```lua
function M.autocmd() ->  nil
```





Registers this module's invalidation autocmds in the "cgxx.statusline"
augroup.

Only invalidation: the segment itself fills in lazily on a cache miss,
so no event has to be responsible for a buffer becoming visible.
`DirChanged` is deliberately absent, since every answer is anchored to
the file's own directory via `git -C` and never to the cwd.








### M.value
---
```lua
function M.value() -> statusline string
```





'statusline' with this module's items spliced in over the leading
`%<%f` of Neovim's default.

That default is not empty: past `%f` it carries the terminal exit code,
LSP progress, `showcmd`, `b:keymap_name`, the busy spinner,
`vim.diagnostic.status()` and the ruler. Assigning a hand-written value
would silently drop all of that, so the default is read back from the
option itself and only its filename item replaced -- which also avoids
pinning a copy of it that would rot across releases. Reading `.default`
rather than the live value also makes this idempotent: it can never
splice into its own output.

The leading `%<` is kept: it is the truncation marker, so a long
repository path shortens from the left in a narrow window, preserving
the filename at the tail.








### M.setup
---
```lua
function M.setup() ->  nil
```





Installs this module's 'statusline'.











## fields
---

### M.items
---
```lua
M.items : string
```



The statusline items this module contributes, in place of `%f`.

Three `%{}` items rather than one, because colour cannot come from the
data. A `%#Group#` only takes effect where the statusline is parsed for
items, and the values here are deliberately never re-parsed (see the
header), so the highlight items sit in this format string *between* the
three calls and every value stays unparsed. Each is a cache read, and
the first of them schedules the resolve the other two then find.

`%*` and not `%#StatusLine#` to close: the reset has to restore
whichever group this window's statusline already had, which is
`StatusLineNC` in every window that is not the current one.









