# class PlainHeaderOpt



- namespace: util









---



## fields
---

### PlainHeaderOpt.commentstring
---
```lua
PlainHeaderOpt.commentstring : string
```



printf-style wrapper








### PlainHeaderOpt.slug
---
```lua
PlainHeaderOpt.slug : string?
```



Repository, boxed as `~slug.git`








### PlainHeaderOpt.fork_slug
---
```lua
PlainHeaderOpt.fork_slug : string?
```



Fork of slug, boxed beneath it








### PlainHeaderOpt.path
---
```lua
PlainHeaderOpt.path : string?
```



Repo-relative path, boxed after `::: `








### PlainHeaderOpt.spdx
---
```lua
PlainHeaderOpt.spdx : string?
```



SPDX identifier; the line is omitted without one








### PlainHeaderOpt.shebang
---
```lua
PlainHeaderOpt.shebang : string?
```



Interpreter line, above the modeline








### PlainHeaderOpt.modeline
---
```lua
PlainHeaderOpt.modeline : util.ModelineOpt?
```



Overrides; `commentstring` is forced









