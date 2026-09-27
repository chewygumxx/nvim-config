# global lua.util.treesitter








---

## methods
---

### M.adjacent
---
```lua
function M.adjacent(
  match: table<integer,TSNode[]>,
  _: integer,
  source: (string|integer),
  predicate: string[]
) ->  boolean
```
@param `match` - Capture id -> matched nodes

@param `_` - Pattern id (unused)

@param `predicate` - `{ "adjacent?", "@a", "@b", ... }`






Treesitter query predicate: `#adjacent? @a @b ...`
True if every captured node is separated only by whitespace, in order.








### M.last_matching
---
```lua
function M.last_matching(
  match: table<integer,TSNode[]>,
  _: integer,
  source: (string|integer),
  predicate: string[]
) ->  boolean
```
@param `match` - Capture id -> matched nodes

@param `_` - Pattern id (unused)

@param `predicate` - `{ "last-matching?", "@a", pat }`






Treesitter query predicate: `#last-matching? @a "pattern"`
True unless some node's next sibling's text matches pattern.








### M.header_line
---
```lua
function M.header_line(
  match: table<integer,TSNode[]>,
  _: integer,
  source: (string|integer),
  predicate: string[]
) ->  boolean
```
@param `match` - Capture id -> matched nodes

@param `_` - Pattern id (unused)

@param `predicate` - `{ "header-line?", "@a", shape }`






Treesitter query predicate: `#header-line? @capture ["repo"|"path"]`
True if every captured node's expanded line matches one of
`HEADER_LINE_PATTERNS` (optionally restricted to a given shape).








### M.setup
---
```lua
function M.setup() ->  nil
```





Registers this module's custom treesitter query predicates.











