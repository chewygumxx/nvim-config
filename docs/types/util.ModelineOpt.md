# class ModelineOpt



- namespace: util









---



## fields
---

### ModelineOpt.buf
---
```lua
ModelineOpt.buf : integer?
```



Fallback source buffer (default: 0)








### ModelineOpt.et
---
```lua
ModelineOpt.et : boolean?
```










### ModelineOpt.expandtab
---
```lua
ModelineOpt.expandtab : boolean?
```



Alias for `et`








### ModelineOpt.sw
---
```lua
ModelineOpt.sw : (boolean|integer)?
```










### ModelineOpt.shiftwidth
---
```lua
ModelineOpt.shiftwidth : (boolean|integer)?
```



Alias for `sw` (default: buf's own, or 4)








### ModelineOpt.ft
---
```lua
ModelineOpt.ft : (boolean|string)?
```










### ModelineOpt.filetype
---
```lua
ModelineOpt.filetype : (boolean|string)?
```



Alias for `ft` (default: buf's own filetype)








### ModelineOpt.append
---
```lua
ModelineOpt.append : string?
```



Extra `:set` clause(s), appended verbatim








### ModelineOpt.commentstring
---
```lua
ModelineOpt.commentstring : string?
```



printf-style wrapper (default: buf's own)









