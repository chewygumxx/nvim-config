# global lua.filetype








---

## methods
---

### M.config
---
```lua
function M.config(opts: vim.api.keyset.create_autocmd.callback_args {
    id = integer,
    event = string,
    group = integer?,
    match = string,
    buf = integer,
    file = string,
    data = any,
}) ->  nil
```












### M.autocmd
---
```lua
function M.autocmd() ->  nil
```





Registers the FileType autocmd that dispatches to a specialised
filetype module, if one is mapped for the triggering filetype.








### M.setup
---
```lua
function M.setup() ->  nil
```





Sets up custom filetype detection.











## fields
---

### M.filetypes
---
```lua
M.filetypes : vim.filetype.add.filetypes {
    pattern: vim.filetype.mapping?,
    extension: vim.filetype.mapping?,
    filename: vim.filetype.mapping?,
}
```










### M.modmap
---
```lua
M.modmap : { [string]: string }
```



Maps a detected filetype to the specialised module that handles it.









