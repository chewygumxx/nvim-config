# global lua.util.shebang








---

## methods
---

### M.get
---
```lua
function M.get(
  file: string?,
  buf: integer?,
  opt: { ft: string? }?
) -> shebang string?
```
@param `file` - Path-check source (default: current buf)

@param `buf` - Filetype fallback source (default: 0)

@param `opt` - Filetype override


@return `shebang` - nil if ft has no configured shebang





Resolves the shebang line for a buffer's filetype, or "#!/bin/false"
for paths under one of `source_dirs` (sourced files, never executed).











