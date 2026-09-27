# global lua.util.lua_checker








---

## methods
---

### M.linters
---
```lua
function M.linters() ->  string[]
```





The linters nvim-lint should run for "lua": selene, plus the active
type checker.








### M.set
---
```lua
function M.set(name: string) ->  nil
```
@param `name` - One of M.checkers






Switches the active type checker. If nvim-lint is already loaded,
applies it immediately and relints the current buffer.








### M.toggle
---
```lua
function M.toggle() ->  nil
```





Switches to the checker after the active one in M.checkers, wrapping
around.











## fields
---

### M.checkers
---
```lua
M.checkers : string[]
```










### M.active
---
```lua
M.active : string
```











