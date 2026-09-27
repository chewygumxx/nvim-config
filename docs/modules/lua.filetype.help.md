# global lua.filetype.help








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





Implements filetype-specific configuration for Neovim help
- Buffer opened via `:edit` rather than `:help`
- It is the only window











