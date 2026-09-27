# global lua.util.markdown_list








---

## methods
---

### M.parse
---
```lua
function M.parse(line: string) -> item cgxx.markdown_list.Item?
```





Parses one line as a Markdown list item, or returns nil if it is not
one.








### M.sibling
---
```lua
function M.sibling(
  item: cgxx.markdown_list.Item {
    indent = string,
    marker = string,
    delim = string,
    spacing = string,
    kind = ("bullet"|"ordered"|"quote"),
    checkbox = string?,
    content = string,
},
  advance: boolean?
) -> prefix string
```
@param `advance` - Increment an ordered marker; true when omitted






The prefix a new sibling of item begins with.

An ordered item advances its number; nothing renumbers the rest of the
list, deliberately, since Markdown renderers do not care and rewriting
lines the user did not touch is worse than a list that counts `1. 2. 4.`.
A checkbox item always continues unchecked, whatever its own state.








### M.empty
---
```lua
function M.empty(item: cgxx.markdown_list.Item {
    indent = string,
    marker = string,
    delim = string,
    spacing = string,
    kind = ("bullet"|"ordered"|"quote"),
    checkbox = string?,
    content = string,
}) -> empty boolean
```





Whether item has no content of its own, ie. it is a marker and nothing
else. Continuing one of those is how an endless list of empty bullets
gets written, so the callers below end the list instead.








### M.open
---
```lua
function M.open(
  below: boolean,
  bufnr: integer?
) -> continued boolean
```





Opens a new line below or above the cursor, continuing the list if the
cursor is on an item, and leaves the buffer in insert mode at the end of
the new line.

Returns false when the cursor is not on a list item, which is the
caller's cue to let `o`/`O` do their ordinary thing rather than this
module reimplementing them.








### M.split
---
```lua
function M.split(bufnr: integer?) -> continued boolean
```





Splits the current line at the cursor and continues the list on the new
line, carrying any text that was to the right of the cursor with it.

The insert-mode counterpart of `M.open`. Returns false when the cursor
is not on a list item.








### M.keymap
---
```lua
function M.keymap(bufnr: integer) ->  nil
```





The buffer-local mappings, attached per Markdown buffer by
`filetype.markdown.setup` and by the compound Markdown filetypes.

`o`/`O` fall back by feeding themselves with remapping off, so a line
that is not a list item behaves exactly as it would unmapped rather than
through an approximation of it.











