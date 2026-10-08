# global lua.util.header








---

## methods
---

### M.description
---
```lua
function M.description(description: string) -> lines string[]
```





Renders a `description:` key, folded when its value would not sit on
one line as plain YAML.

Folded (`>-`, so the value keeps no trailing newline) when the value is
longer than `M.description_limit` or is anything `util.text.yaml_scalar`
would have to quote, since a block scalar needs no quoting at all. An
empty value is a bare key, YAML's null, because a folded scalar with no
body would read the next key as its content.

Shared with `util.frontmatter`, which rewrites a hand-written value into
this same form on save.








### M.box
---
```lua
function M.box(
  slug: string?,
  fork_slug: string?,
  path: string?
) -> lines string[]
```





The lines of the HTML comment box naming a file's repository and path,
`<!--` to `-->` inclusive.

Every line inside opens `   - `, aligning the dashes under the `!` of
`<!--`, the way a C block comment aligns its `*`s.








### M.frontmatter
---
```lua
function M.frontmatter(opt: util.FrontmatterOpt {
    title = string,
    slug = string?,
    fork_slug = string?,
    path = string?,
    spdx = string?,
    filetype = string?,
    shiftwidth = integer?,
    foldlevel = integer?,
    description = string?,
    tags = string[]?,
    ctime = string?,
    mtime = string?,
}) -> frontmatter util.Frontmatter {
    head = string[],
    tail = string[],
}
```





Renders a Markdown file's header: YAML frontmatter and the boxed
repository notation at its head, and the modeline at its foot.

The frontmatter is plain data, so a YAML parser sees nothing it does
not need. The repository box is an HTML comment, which no renderer
shows. The modeline goes last, since Vim reads one from the final
'modelines' lines as readily as from the first and frontmatter must
open on line 1.

Shared with `util.nex`, which renders the same shape for a note: this is
the one description of the format, so a change here reaches both.








### M.plain_box
---
```lua
function M.plain_box(
  commentstring: string,
  slug: string?,
  fork_slug: string?,
  path: string
) -> lines string[]
```





The plain-comment box naming a file's repository and path, padded by
two empty comment lines either side, each wrapped in commentstring.

The plain counterpart of `M.box`. Split out of `M.plain` because
`M.apply` re-renders the box alone on every save, to follow a file that
has been renamed or moved.








### M.find_box
---
```lua
function M.find_box(
  lines: string[],
  commentstring: string
)
 -> first integer?
 -> last integer?

```





The 1-indexed first and last lines of the box `M.plain_box` renders, if
lines carry one near their head.

Recognised by shape rather than content: two empty comment lines, one
to three that name a repository or path, ie. open on `~` or `:`, and two
more empty ones. A padded comment of prose has the same frame and is
left alone, since rewriting it would replace the prose with a path.








### M.plain
---
```lua
function M.plain(opt: util.PlainHeaderOpt {
    commentstring = string,
    slug = string?,
    fork_slug = string?,
    path = string?,
    spdx = string?,
    shebang = string?,
    modeline = util.ModelineOpt?,
}) -> lines string[]
```





Renders the plain-comment form of this repository's file header: an
optional shebang, the modeline, the SPDX line and the boxed repository
notation, each wrapped in opt.commentstring.

Split out of `M.insert` rather than left inline there because
`util.vimdoc` renders the same box into generated help, where there is
no buffer to take a 'commentstring' or a filetype from. This is now the
one description of the plain shape, as `M.frontmatter` is of the
Markdown one.








### M.locate
---
```lua
function M.locate(file: string) -> location util.HeaderLocation {
    path = string,
    slug = string?,
    fork_slug = string?,
    upstream = string?,
}
```





Where file lives, as the header box names it.

A fork is boxed upstream first and the fork beneath it, so when an
`upstream` remote exists its slug is what `slug` holds and the file's
own repository moves to `fork_slug`. Anything under `~/.config` is the
dotfiles repository's, at the path chezmoi gives it there.

Split out of `M.insert` because the box is re-derived on save, to
follow a file that has been renamed or moved; `M.located` caches it for
that.








### M.insert
---
```lua
function M.insert(
  file: string?,
  buf: integer?,
  opt: util.HeaderInsertOpt?
) ->  nil
```
@param `file` - Slug/path source (default: current buf)

@param `buf` - Buffer to insert into (default: buf 0)






Inserts a templated header into buf: the plain-comment form (modeline,
SPDX line, repository box) at its head, or for a "markdown" buffer the
frontmatter and box at its head and the modeline at its foot.








### M.located
---
```lua
function M.located(
  buf: integer,
  name: string
) -> location util.HeaderLocation {
    path = string,
    slug = string?,
    fork_slug = string?,
    upstream = string?,
}
```





`M.locate` of buf's file, remembered against the name it was looked up
for.

A lookup is up to three synchronous git spawns, and `M.apply` and
`util.frontmatter.apply` run on every save of a file with a header, so
it is answered once per buffer name. Keyed by name rather than flagged
once, so a `:saveas` or `:file` that moves the buffer looks again.








### M.apply
---
```lua
function M.apply(buf: integer) ->  nil
```





Re-renders buf's plain-comment box for where its file now lives, if it
carries one, as one undo step with whatever change is being saved.

The plain counterpart of `util.frontmatter.apply`, which already does
the same for a Markdown header's box, so Markdown is left to it. Only
the box is touched: the SPDX line names a licence chosen when the file
was written, which a move gives no reason to revisit.








### M.command
---
```lua
function M.command() ->  nil
```





`XXInsertHeader` callback: inserts a header into the current buffer.








### M.autocmd
---
```lua
function M.autocmd() ->  nil
```





Registers the BufNewFile/FileType autocmd pair that defers header
insertion on a new file buffer until its filetype is known, and the
BufWritePre one that keeps an existing header's box true on save.








### M.setup
---
```lua
function M.setup() ->  nil
```





Registers the `XXInsertHeader` user command and its supporting autocmds.











## fields
---

### M.description_limit
---
```lua
M.description_limit : integer
```



A `description:` longer than this is folded rather than left on one
line. 66 rather than 80 because the key and its separator take the
difference, so a value at this length still ends within 80 columns.









