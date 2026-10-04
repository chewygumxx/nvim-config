# class HeaderLocation



- namespace: util









---



## fields
---

### HeaderLocation.path
---
```lua
HeaderLocation.path : string
```



Repo-relative (`:/a.md`), or `~`-relative outside one








### HeaderLocation.slug
---
```lua
HeaderLocation.slug : string?
```



The repository, upstream first when a fork








### HeaderLocation.fork_slug
---
```lua
HeaderLocation.fork_slug : string?
```



The fork, when the file belongs to one








### HeaderLocation.upstream
---
```lua
HeaderLocation.upstream : string?
```



The upstream's slug, which decides the licence









