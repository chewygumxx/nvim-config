# global lua.filetype.markdown








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





Attaches the buffer-local keymaps from `util.markdown_table` and
`util.markdown_list`.

`lua/filetype/init.lua` dispatches exactly one module per filetype, so
the compound Markdown filetypes cannot inherit this by being Markdown:
`filetype.nex_note` and `filetype.agentprompt` call it themselves, the same
way they already copy `local_opts` and `hlgroup_defs`.











## fields
---

### M.local_opts
---
```lua
M.local_opts : { [string]: (boolean|string|number) }
```



`autoindent` is what lets `n` in 'formatoptions' indent by
'formatlistpat' at all. `comments` drops the bundled ftplugin's `fb:-`,
`fb:*` and `fb:+`, keeping only the blockquote: as comment leaders they
outrank 'formatlistpat' and always hang by two columns, whatever follows
the bullet. See `util.markdown_format` for 'formatexpr'.








### M.hlgroup_defs
---
```lua
M.hlgroup_defs : { [string]: vim.api.keyset.highlight }
```











