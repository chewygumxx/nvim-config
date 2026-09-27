# global lua.util.lazy








---

## methods
---

### M.install
---
```lua
function M.install(
  url: string,
  path: string,
  branch: string
) -> syscall_code number
```
@param `url` - Repository URL

@param `path` - Clone destination

@param `branch` - Repository branch


@return `syscall_code` - Exit code of git clone





Clones remote repository of lazy.nvim








### M.setup
---
```lua
function M.setup(opts: LazyConfig?) ->  nil
```





Installs lazy.nvim if not found, merges opts with defaults and calls
require("lazy").setup(opts)











## fields
---

### M.defaults
---
```lua
M.defaults : LazyConfig {
    [1]: any,
    url: nil,
    branch: string = "stable",
    name: string = "lazy",
    spec: LazySpec,
    root: string,
    path: string,
    state: string,
    lockfile: string,
    local_spec: boolean = true,
    concurrency: integer?,
    diff: { cmd = "git" },
    ...(+13)
}
```











