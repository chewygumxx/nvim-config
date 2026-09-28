# global lua.filetype.nex_note








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
})-> nil
```



Markdown's own `setup()`, unchanged: the table keymaps are as welcome in
a note as in any other Markdown buffer, and a note gets them only
because it asks: `lua/filetype/init.lua` runs one module per filetype.











## fields
---

### M.local_opts
---
```lua
M.local_opts : { [string]: (boolean|string|number) }
```



Markdown's own buffer-local options, plus the prose- and
structure-oriented ones a note wants on top.

The fold settings are what make the `foldlevel=3` in a note's own
modeline mean something: they resolve to Tree-sitter's heading folds,
so a note opens with its top three heading levels expanded and
anything deeper folded away. `vim.treesitter.foldexpr()` degrades to
"no folds" rather than erroring when the Markdown parser is absent.








### M.hlgroup_defs
---
```lua
M.hlgroup_defs : { [string]: vim.api.keyset.highlight }
```



Markdown's own highlight links, unchanged.

These are global (`nvim_set_hl(0, ...)`) rather than buffer-local, so
there is deliberately nothing note-specific here: anything added would
recolour every plain Markdown buffer too, which is not this filetype's
business. Notes are distinguished by their options above, not their
colours.









