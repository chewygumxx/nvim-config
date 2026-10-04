# global lua.util.nex








---

## methods
---

### M.slugify
---
```lua
function M.slugify(text: string) -> slug string
```

@return `slug` - Empty if text holds no alphanumerics





Reduces text to the lowercase, hyphen-separated form used in a note's
filename.








### M.yaml_scalar
---
```lua
function M.yaml_scalar(text: string) -> scalar string
```





Renders text as a YAML flow scalar, double-quoting it only when a
plain scalar would be ambiguous or invalid.

Kept as part of this module's surface, since a caller assembling a note
has no reason to know where the quoting rule lives; the rule itself is
`util.text`'s, shared with `util.header.frontmatter`.








### M.filename
---
```lua
function M.filename(note: cgxx.nex.Note {
    title = string,
    description = string?,
    tags = string[]?,
    ctime = string?,
}) -> filename string
```





Builds note's filename, `M.root`/`M.subdir`-relative.








### M.path
---
```lua
function M.path(note: cgxx.nex.Note {
    title = string,
    description = string?,
    tags = string[]?,
    ctime = string?,
}) -> path string
```





Builds note's absolute path.








### M.render
---
```lua
function M.render(note: cgxx.nex.Note {
    title = string,
    description = string?,
    tags = string[]?,
    ctime = string?,
}) -> lines string[]
```





Renders note as the full text of its file.








### M.is_worktree
---
```lua
function M.is_worktree() ->  boolean
```





Whether `M.root` exists and is the working tree of a git repository.








### M.select_tags
---
```lua
function M.select_tags(on_choice: fun(tags: string[]?)) ->  nil
```
@param `on_choice` - Receives tags in `M.tags` order






Prompts for a tag subset via `snacks.picker`'s multi-select (`<Tab>`
marks, `<CR>` confirms, falling back to the item under the cursor when
nothing is marked). Calls on_choice with nil if the picker is closed
without confirming, or if snacks is unavailable.








### M.create
---
```lua
function M.create(note: cgxx.nex.Note {
    title = string,
    description = string?,
    tags = string[]?,
    ctime = string?,
}) ->  nil
```





Writes note to disk and opens it, cursor on its trailing blank line.
Refuses to overwrite an existing note of the same name.








### M.new_note
---
```lua
function M.new_note() ->  nil
```





Prompts for a title, a description and a tag selection, then creates
the note. Aborts silently at any prompt that is cancelled, and on an
empty title (which has no filename to slugify).








### M.is_note
---
```lua
function M.is_note(path: string?) ->  boolean
```





Whether path is a note file inside this repository's note directory.
Resolved by location rather than by filetype: where the file sits is
what decides whether committing it is this module's business.








### M.commit
---
```lua
function M.commit(
  path: string,
  report: boolean?
) ->  nil
```
@param `path` - Absolute path of a note inside `M.root`

@param `report` - Notify when the write changed nothing, too






Stages and commits the note at path.








### M.enable
---
```lua
function M.enable(bufnr: integer?) ->  nil
```
@param `bufnr` - Default: current buffer






Enables commit-on-write for bufnr.








### M.disable
---
```lua
function M.disable(bufnr: integer?) ->  nil
```
@param `bufnr` - Default: current buffer






Disables commit-on-write for bufnr.








### M.toggle
---
```lua
function M.toggle(bufnr: integer?) ->  nil
```
@param `bufnr` - Default: current buffer






Toggles commit-on-write for bufnr.








### M.autocmd
---
```lua
function M.autocmd() ->  nil
```





Registers this module's autocmds in the "cgxx.nex" augroup.








### M.command
---
```lua
function M.command(opts: vim.api.keyset.create_user_command.command_args {
    name = string,
    args = string,
    fargs = string[],
    nargs = string,
    bang = boolean,
    line1 = integer,
    line2 = integer,
    range = integer,
    count = integer,
    reg = string,
    mods = string,
    smods = table,
}) ->  nil
```





`nvim_create_user_command` callback backing `XXNexNote`.








### M.complete
---
```lua
function M.complete() -> actions string[]
```





`nvim_create_user_command` completion for `XXNexNote`.











## fields
---

### M.root
---
```lua
M.root : string
```



Repository the notes live in.








### M.subdir
---
```lua
M.subdir : string
```



Note subdirectory, relative to `M.root`.








### M.slug
---
```lua
M.slug : string
```



Repository slug, as written into a note's boxed header.








### M.filetype
---
```lua
M.filetype : string
```



Compound filetype a note resolves to.








### M.extension
---
```lua
M.extension : string
```



Suffix every note filename carries, `M.slugify`'d title excluded.








### M.foldlevel
---
```lua
M.foldlevel : integer
```



Fold level a note opens at, per its modeline.








### M.tags
---
```lua
M.tags : string[]
```



Tag vocabulary offered by the multi-select. Authoritative: the picker
takes no free-text entry, so a tag that is not here cannot be chosen.
Edit this list to grow the vocabulary.








### M.note_path_pattern
---
```lua
M.note_path_pattern : string
```



Full-path pattern (for `vim.filetype.add`) matching a note.
`vim.filetype.add` implicitly anchors user-supplied patterns with
`^...$`, so this must NOT have a trailing `$` of its own.








### M.cursor_offset
---
```lua
M.cursor_offset : integer
```



How many lines above the end of a freshly rendered note the cursor is
left: past the modeline and the blank line separating it from the body.









