# global lua.filetype.agentprompt








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
`util.agentprompt`), to where the reply is actually composed. The fold
itself is applied per-window by `util.agentprompt`'s `BufWinEnter` autocmd,
since folds don't carry over between windows on the same buffer.











## fields
---

### M.local_opts
---
```lua
M.local_opts: table
```



A copy rather than the table itself, which `filetype.nex_note` aliases:
assigning into an alias would hand every Markdown buffer this width








### M.hlgroup_defs
---
```lua
M.hlgroup_defs : { [string]: vim.api.keyset.highlight }
```











