# global lua.util.yamllint








---

## methods
---

### M.cwd
---
```lua
function M.cwd(buf: integer) ->  string?
```





The directory yamllint runs in for `buf`: the nearest one holding a
configuration, or the buffer's own where none does, leaving yamllint
to fall back on the user's. Nil for a buffer with no file behind it.
Searched from the name, since `vim.fs.root(buf)` starts from the
process cwd for any buffer with a `buftype`.








### M.path
---
```lua
function M.path(buf: integer) ->  string
```





`buf`'s path relative to `M.cwd`, which is what `ignore:` matches.








### M.parse
---
```lua
function M.parse(
  output: string,
  buf: integer,
  cwd: string?
) ->  vim.Diagnostic[]
```
@param `cwd` - the directory yamllint ran in






Diagnostics for `buf` out of yamllint's `parsable` output, whose
paths are relative to `cwd`. A line about any other file is dropped
rather than misplaced.











## fields
---

### M.files
---
```lua
M.files : string[]
```



The names yamllint looks for, in its order of preference.








### M.linter
---
```lua
M.linter : lint.Linter
```



Replaces nvim-lint's bundled `yamllint`. The directory it runs in is
passed per buffer from `M.cwd`, since a linter's own `cwd` is fixed.









