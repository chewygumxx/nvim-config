# global lua.util.modeline








---

## methods
---

### M.base
---
```lua
function M.base(opt: util.ModelineOpt?) -> modeline string
```





Builds a `vim:set ...:` modeline comment from opt, falling back to
buf's own option values for anything left unset.











