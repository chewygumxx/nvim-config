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








### M.is_mise
---
```lua
function M.is_mise(
  _match: table<integer,TSNode[]>,
  _pattern: integer,
  source: (string|integer),
  _predicate: string[]
) ->  boolean
```
@param `source` - Buffer number, or anonymous source text






Treesitter query predicate: `#is-mise?`
Restricts TOML script injections to mise config filenames and directories.








### M.shebang_lang
---
```lua
function M.shebang_lang(text: string) -> lang string?
```
@param `text` - Script text, optionally still inside its TOML quotes






Returns the parser a script's shebang names, or nil when it has none.
`env`'s flags and assignments are skipped, so `#!/usr/bin/env -S uv run`
names `uv`, and a version suffix is dropped, so `python3.12` is `python`.








### M.set_lang_from_shebang
---
```lua
function M.set_lang_from_shebang(
  match: table<integer,TSNode[]>,
  _pattern: integer,
  source: (string|integer),
  predicate: any[],
  metadata: vim.treesitter.query.TSMetadata {
    range = (Range2|Range4|Range6)?,
    offset = Range4?,
    conceal = string?,
    bo.commentstring = string?,
    [integer] = vim.treesitter.query.TSMetadata?,
    [string] = (string|integer)?,
}
) ->  nil
```
@param `source` - Buffer number, or source text






Treesitter query directive: `#set-lang-from-shebang! @capture default`
Sets `injection.language` to the parser the captured script's shebang
names, or to `default` when it has none.








### M.setup
---
```lua
function M.setup() ->  nil
```





Registers this module's custom treesitter query predicates and directives.











## fields
---

### M.interpreters
---
```lua
M.interpreters : table<string,string>
```



Interpreters a shebang can name whose parser goes by another name. A name
absent here is taken to be its own parser's. `tsx` is the TypeScript
runner, whose scripts the TSX parser's JSX grammar would misread.









