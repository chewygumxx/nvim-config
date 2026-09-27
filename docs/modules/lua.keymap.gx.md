# global lua.keymap.gx








---

## methods
---

### M.url_at_cursor
---
```lua
function M.url_at_cursor() ->  string?
```












### M.callback
---
```lua
function M.callback() ->  nil
```












### M.setup
---
```lua
function M.setup() ->  nil
```















## fields
---

### M.desc
---
```lua
M.desc: string = "Open URL or owner/repo under cursor"
```










### M.pattern_maps
---
```lua
M.pattern_maps : cgxx.keymap.gx.pattern_map[]
```










### M.fallback
---
```lua
M.fallback : vim.api.keyset.get_keymap {
    abbr: (0|1)?,
    buf: (0|1)?,
    callback: (function)?,
    desc: string?,
    expr: (0|1)?,
    lhs: string?,
    lhsraw: string?,
    lhsrawalt: string?,
    lnum: integer?,
    mode: string?,
    mode_bits: integer?,
    noremap: (0|1)?,
    ...(+6)
}
```











