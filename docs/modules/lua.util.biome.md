# global lua.util.biome








---

## methods
---

### M.dir
---
```lua
function M.dir(buf: integer) -> dir string
```





The directory a buffer's search starts from: its file's directory, or
the working directory for a buffer with no file behind it.








### M.configures
---
```lua
function M.configures(
  dir: string,
  tool: util.biome.Tool {
    files = string[],
    package_keys = string[],
    dependencies = string[],
}
) ->  boolean
```





Whether the repository holding `dir` configures `tool`, searching
from `dir` upward and no further than the repository root.








### M.enabled
---
```lua
function M.enabled(buf: integer) ->  boolean
```





Whether Biome owns a buffer: it does when the repository configures
Biome, or when it configures neither eslint nor prettier.











## fields
---

### M.biome
---
```lua
M.biome : util.biome.Tool {
    files: string[],
    package_keys: string[],
    dependencies: string[],
}
```



Biome's own evidence.








### M.eslint
---
```lua
M.eslint : util.biome.Tool {
    files: string[],
    package_keys: string[],
    dependencies: string[],
}
```



An eslint configuration, flat or legacy. `lsp/eslint.lua` starts the
server by this and nothing else.








### M.prettier
---
```lua
M.prettier : util.biome.Tool {
    files: string[],
    package_keys: string[],
    dependencies: string[],
}
```



A prettier configuration.








### M.incumbent
---
```lua
M.incumbent : util.biome.Tool {
    files: string[],
    package_keys: string[],
    dependencies: string[],
}
```



The evidence that a repository has chosen eslint or prettier. Only
configuration counts, not a dependency: a transitive `prettier` in
`package.json` says nothing about how the repository wants formatting.









