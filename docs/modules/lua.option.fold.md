# global lua.option.fold








---

## methods
---

### M.foldtext
---
```lua
function M.foldtext() -> text string
```





`foldtext` callback (`v:lua.require("option.fold").foldtext()`):
renders the folded line's own text, indent-collapsed into "~", followed
by a right-aligned "[N lines] [lvl=N]" summary. Reads fold state from
`vim.v.fold*`.








### M.setup
---
```lua
function M.setup() ->  nil
```





Registers `foldtext` as a global and applies this module's fold
option values.











