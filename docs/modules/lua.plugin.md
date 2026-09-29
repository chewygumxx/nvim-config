# global lua.plugin








---

## methods
---

### M.factory
---
```lua
function M.factory(group: ("elide"|"condemn")) ->  LazySpecImport
```





Returns a function that returns the LazySpecImport of the provided group:
bare `{ slug, cond/enabled = false }` overrides, merged by lazy.nvim into
each plugin's real spec from `{ import = "spec" }` regardless of order.








### M.import
---
```lua
function M.import() ->  LazySpecImport[]
```












### M.setup
---
```lua
function M.setup() ->  nil
```





Configures and arranges spec order for lazy.nvim











## fields
---

### M.elide
---
```lua
M.elide : ("L3MON4D3/LuaSnip","MeanderingProgrammer/render-markdown.nvim","OXY2DEV/markview.nvim","debugloop/telescope-undo.nvim","folke/lazydev.nvim","folke/noice.nvim","jakewvincent/mkdnflow.nvim","kndndrj/nvim-dbee","m4xshen/hardtime.nvim","mikavilpas/yazi.nvim"...)
```










### M.condemn
---
```lua
M.condemn : ("nvim-neorg/neorg","nvim-orgmode/orgmode")
```











