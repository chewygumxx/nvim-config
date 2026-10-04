# global lua.util.spell








---

## methods
---

### M.files
---
```lua
function M.files(buf: integer?) -> paths string[]
```
@param `buf` - (default: current buffer)






Every word list named in buf's 'spellfile', as absolute paths.








### M.stale
---
```lua
function M.stale(path: string) -> stale boolean
```
@param `path` - The `.add` word list






Whether path's compiled `.spl` is missing or older than path itself.








### M.refresh
---
```lua
function M.refresh(buf: integer?) -> compiled string[]
```
@param `buf` - (default: current buffer)


@return `compiled` - The word lists that were recompiled





Recompiles each stale word list in buf's 'spellfile'.








### M.autocmd
---
```lua
function M.autocmd() ->  nil
```





Registers the autocmds that recompile a stale word list once at startup
and again whenever one is written from a buffer.











