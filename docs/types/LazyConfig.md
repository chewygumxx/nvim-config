# class LazyConfig











---



## fields
---

### LazyConfig.[1]
---
```lua
LazyConfig.[1] : unknown
```



Repository URL or GitHub slug








### LazyConfig.url
---
```lua
LazyConfig.url : nil
```



Resolved URL: left unset so `M.setup()` derives it from `git.url_format`
unless a caller passes one explicitly.








### LazyConfig.branch
---
```lua
LazyConfig.branch: string = "stable"
```




Repository branch.

Bootstrap-only, and deliberately so. `M.install()` is the sole reader
of this field: lazy.nvim's own options carry no `branch`, and once
installed it manages itself through a spec it hardcodes as
`{ "folke/lazy.nvim" }` with no branch of its own, whereupon
`Git.get_branch` falls back to `origin/HEAD`. So this names the branch
a machine without lazy.nvim clones, and the first `:Lazy update`
afterwards returns that copy to the remote's default branch and
records it in `lazy-lock.json`. Holding it on `stable` for good would
take a real `lua/spec/lazy.nvim.lua` declaring the branch, which is a
larger change than the bootstrap wants to make on its own.








### LazyConfig.name
---
```lua
LazyConfig.name: string = "lazy"
```



Name of lazy.nvim, sets directory names








### LazyConfig.spec
---
```lua
LazyConfig.spec : LazySpec
```










### LazyConfig.root
---
```lua
LazyConfig.root : string
```



Plugin installation directory








### LazyConfig.path
---
```lua
LazyConfig.path : string
```



lazy.nvim installation directory








### LazyConfig.state
---
```lua
LazyConfig.state : string
```



State information file








### LazyConfig.lockfile
---
```lua
LazyConfig.lockfile : string
```




Post-update lockfile.

lazy.nvim's own default, ie. inside `stdpath("config")`, which is a
checkout of this repository on every machine it is deployed to. It
used to sit beside `state.json` under `stdpath("state")`, which
classified the lock as machine state; it is tracked instead now, so
that `:Lazy restore` gives every machine the same commits and so CI
has an honest cache key for a plugin install.

One file serves Arch, Termux and Herdr despite their differing
plugin sets. lazy.nvim's writer keeps the entries of plugins it is
not currently managing, ie. anything in `Config.spec.disabled` or
`Config.spec.ignore_installed`, so the mason trio `lua/plugin.lua`
condemns under Termux keeps its pin when a Termux sync writes the
file rather than being pruned and re-added on the next Arch sync.
That same retention is why entries exist for everything `M.elide`
and `M.condemn` name: their presence records a pin to return to, not
that the plugin is in use.








### LazyConfig.local_spec
---
```lua
LazyConfig.local_spec: true
```



Load project-local `.lazy.lua` LazySpec[] file`








### LazyConfig.concurrency
---
```lua
LazyConfig.concurrency : integer?
```



Concurrent task limit








### LazyConfig.diff
---
```lua
LazyConfig.diff: table
```










### LazyConfig.git
---
```lua
LazyConfig.git: table
```










### LazyConfig.defaults
---
```lua
LazyConfig.defaults: table
```



Plugin spec defaults








### LazyConfig.dev
---
```lua
LazyConfig.dev: table
```



Locally available plugins








### LazyConfig.install
---
```lua
LazyConfig.install: table
```










### LazyConfig.performance
---
```lua
LazyConfig.performance: table
```










### LazyConfig.readme
---
```lua
LazyConfig.readme: table
```



Generate `:help` documentation from README








### LazyConfig.profiling
---
```lua
LazyConfig.profiling: table
```



Additional stats provided on the "Debug" tab








### LazyConfig.change_detection
---
```lua
LazyConfig.change_detection: table
```



Watch configuration files and reload the UI on change








### LazyConfig.checker
---
```lua
LazyConfig.checker: table
```



Automatic update checks








### LazyConfig.pkg
---
```lua
LazyConfig.pkg: table
```










### LazyConfig.rocks
---
```lua
LazyConfig.rocks: table
```










### LazyConfig.ui
---
```lua
LazyConfig.ui: table
```










### LazyConfig.debug
---
```lua
LazyConfig.debug: false
```











