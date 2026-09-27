# global lua.util.vimdoc








---

## methods
---

### M.fit
---
```lua
function M.fit(
  lines: string[],
  indent: string
) -> lines string[]
```
@param `indent` - Prefix each continuation line carries






Breaks any line wider than `M.width` at the width, continuing the
remainder at indent.

`util.text.wrap_comment` breaks on whitespace alone, which is right for
prose and wrong here: an option value like 'statusline' or a slash-run
like a command's argument list is one token and would be emitted whole,
past the column a help window shows. Truncating instead would make the
page state the value wrongly, so the token is broken and kept.








### M.flush_right
---
```lua
function M.flush_right(
  left: string,
  tag: string
) -> line string
```
@param `tag` - Bare tag name, rendered as `*tag*`






Returns left with tag placed flush right against `M.width`, separated
by at least one space.








### M.rule
---
```lua
function M.rule(char: string) -> rule string
```
@param `char` - Single character, conventionally "=" or "-"






Returns a full-width rule of char, the delimiter above a heading.








### M.entry
---
```lua
function M.entry(entry: cgxx.vimdoc.Entry {
    lhs = string,
    desc = string?,
    tag = string?,
}) -> lines string[]
```





Renders one entry as its tag line, if any, then its two columns.

The description hangs at `M.indent`, and the left column joins the
first description line when it fits in that gutter. A tag takes a line
of its own above rather than sharing the first: sharing would push a
long `lhs` and its tag past `M.width` with no good way to recover.








### M.section
---
```lua
function M.section(section: cgxx.vimdoc.Section {
    title = string,
    tag = string,
    intro = string?,
    entries = cgxx.vimdoc.Entry[]?,
}) -> lines string[]
```





Renders one section: its rule, its tagged heading, its intro prose and
its entries.








### M.contents
---
```lua
function M.contents(sections: cgxx.vimdoc.Section[]) -> lines string[]
```





Renders the table of contents: one dotted line per section, linking to
its tag.

Numbered rather than bulleted because `:help` readers navigate a
contents block by `CTRL-]` on the link, and the number is what makes a
section referable in prose elsewhere.








### M.render
---
```lua
function M.render(opt: cgxx.vimdoc.Opt {
    file = string,
    tagline = string,
    slug = string?,
    path = string?,
    spdx = string?,
    sections = cgxx.vimdoc.Section[],
}) -> lines string[]
```





Renders a whole help file, header box included.

No closing modeline is emitted, though `runtime/doc/*.txt` carries one:
the header's own modeline sits inside the first five lines, which is
where Vim reads one from, so a second would be a second statement of
the same thing.











## fields
---

### M.width
---
```lua
M.width : integer
```



Column a help file's text wraps at. Vim's own, not this repository's.








### M.indent
---
```lua
M.indent : integer
```



Column an entry's description starts at, and the hanging indent its
continuation lines take. Wide enough for `<leader>` plus two keys and
for the longest `XX`-prefixed command name.









