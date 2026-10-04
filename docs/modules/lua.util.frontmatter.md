# global lua.util.frontmatter








---

## methods
---

### M.close
---
```lua
function M.close(lines: string[]) -> close integer?
```





The 1-indexed line of the `---` that closes lines' frontmatter, if
lines open on one and carry a `ctime:` key inside it.








### M.heading
---
```lua
function M.heading(
  lines: string[],
  ranges: cgxx.markdown_format.Range[]
) -> title string?
```
@param `ranges` - From `util.markdown_format.protected`






The text of the first ATX level-one heading outside every protected
block, ie. not in a fence, frontmatter or HTML comment.








### M.unquote
---
```lua
function M.unquote(value: string) -> text string?
```
@param `value` - Everything after `key: `






A single-line YAML scalar's value, unquoted, or nil for anything
spanning more than one line or not a scalar at all.








### M.sync
---
```lua
function M.sync(
  lines: string[],
  close: integer,
  ranges: cgxx.markdown_format.Range[],
  location: util.HeaderLocation?,
  today: string
)
 -> header string[]
 -> last integer

```
@param `close` - From `M.close`

@param `location` - Box to write, if known

@param `today` - YYYY-MM-DD






The header lines a save should leave, given the lines it has now.

Returns the replacement for lines 1 through `last`, where `last` is the
end of the repository box if one directly follows the frontmatter, and
the frontmatter's own close otherwise.








### M.apply
---
```lua
function M.apply(buf: integer) ->  nil
```





Re-renders buf's header in place, if it has one, as one undo step with
whatever change is being saved.








### M.autocmd
---
```lua
function M.autocmd() ->  nil
```





Registers the `BufWritePre` autocmd that runs `M.apply` on a modified
Markdown buffer, compound filetypes included.











