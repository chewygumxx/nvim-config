# global lua.filetype.claude








---

## methods
---

### M.setup
---
```lua
function M.setup(opts: vim.api.keyset.create_autocmd.callback_args {
    id = integer,
    event = string,
    group = integer?,
    match = string,
    buf = integer,
    file = string,
    data = any,
}) ->  nil
```





Moves the cursor past the last-response divider line (if present, see
`util.claude`), to where the reply is actually composed. The fold
itself is applied per-window by `util.claude`'s `BufWinEnter` autocmd,
since folds don't carry over between windows on the same buffer.











## fields
---

### M.local_opts
---
```lua
M.local_opts : { [string]: (boolean|string|number) }
```










### M.hlgroup_defs
---
```lua
M.hlgroup_defs : { [string]: vim.api.keyset.highlight }
```











