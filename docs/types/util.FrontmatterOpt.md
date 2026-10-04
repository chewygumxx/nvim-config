# class FrontmatterOpt



- namespace: util









---



## fields
---

### FrontmatterOpt.title
---
```lua
FrontmatterOpt.title : string
```



Heading, and the `title:` key








### FrontmatterOpt.slug
---
```lua
FrontmatterOpt.slug : string?
```



Repository, boxed as `~slug.git`








### FrontmatterOpt.fork_slug
---
```lua
FrontmatterOpt.fork_slug : string?
```



Fork of slug, boxed beneath it








### FrontmatterOpt.path
---
```lua
FrontmatterOpt.path : string?
```



Repo-relative path, boxed after `::: `








### FrontmatterOpt.spdx
---
```lua
FrontmatterOpt.spdx : string?
```



SPDX identifier; the key is omitted without one








### FrontmatterOpt.filetype
---
```lua
FrontmatterOpt.filetype : string?
```



Modeline `filetype` (default: "markdown")








### FrontmatterOpt.shiftwidth
---
```lua
FrontmatterOpt.shiftwidth : integer?
```



Modeline `shiftwidth` (default: 2)








### FrontmatterOpt.foldlevel
---
```lua
FrontmatterOpt.foldlevel : integer?
```



Modeline `foldlevel`; omitted without one








### FrontmatterOpt.description
---
```lua
FrontmatterOpt.description : string?
```



Value of `description:`, folded if long








### FrontmatterOpt.tags
---
```lua
FrontmatterOpt.tags : string[]?
```



`tags:` block sequence, in the order given








### FrontmatterOpt.ctime
---
```lua
FrontmatterOpt.ctime : string?
```



YYYY-MM-DD (default: today)








### FrontmatterOpt.mtime
---
```lua
FrontmatterOpt.mtime : string?
```



YYYY-MM-DD (default: ctime)









