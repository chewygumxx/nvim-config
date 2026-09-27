# global lua.util.header








---

## methods
---

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
}) -> lines string[]
```





Renders a Markdown file's YAML frontmatter, opening `---` to closing
`---` inclusive.

The modeline and the boxed repository notation live inside a `__cgxx: |`
literal block scalar rather than above the frontmatter, so that a file
opens with both a valid YAML document at its head and a modeline Vim
still reads. Inside that block the comment syntax is the frontmatter's
own (`# %s`) and not the buffer's, which is why nothing here consults
'commentstring'.

Shared with `util.nex`, which renders the same shape for a note: this is
the one description of the format, so a change here reaches both.








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






Prepends buf with a templated header (modeline, SPDX line, repo slug
and path), then Markdown frontmatter if buf's filetype is "markdown".








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
insertion on a new file buffer until its filetype is known.








### M.setup
---
```lua
function M.setup() ->  nil
```





Registers the `XXInsertHeader` user command and its supporting autocmds.











