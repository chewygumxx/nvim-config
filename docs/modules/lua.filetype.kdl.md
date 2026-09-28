# global lua.filetype.kdl








---



## fields
---

### M.hlgroup_defs
---
```lua
M.hlgroup_defs : { [string]: vim.api.keyset.highlight }
```



Tree-sitter captures are scoped to `.kdl`, as `filetype.markdown` scopes
its own: `nvim_set_hl` is global, so a bare `@type` would recolour every
language. `kdlNode` is a syntax group and already KDL's alone.









