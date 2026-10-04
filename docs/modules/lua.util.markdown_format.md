# global lua.util.markdown_format








---

## methods
---

### M.protected
---
```lua
function M.protected(bufnr: integer?) -> ranges cgxx.markdown_format.Range[]
```
@param `bufnr` - (default: current buffer)






Every block in bufnr that is not prose, as 1-indexed line ranges.

Parses the buffer itself rather than trusting an existing tree, for the
reason `util.markdown_table` gives: nothing may have parsed it yet.








### M.runs
---
```lua
function M.runs(
  ranges: cgxx.markdown_format.Range[],
  first: integer,
  last: integer
) -> runs cgxx.markdown_format.Range[]
```
@param `first` - 1-indexed

@param `last` - 1-indexed, inclusive


@return `runs` - In buffer order





Splits first..last into the runs of lines outside every range.








### M.formatexpr
---
```lua
function M.formatexpr() -> handled integer
```

@return `handled` - 0 when done here, 1 to defer to Vim





The 'formatexpr' itself, ie. `v:lua.require'util.markdown_format'
.formatexpr()`.

In insert mode Vim calls this to auto-wrap the line being typed, with
`v:char` set: returning 1 hands that back to the internal formatter,
and returning 0 on a protected line is what stops a long line of code
in a fence wrapping as it is typed.











