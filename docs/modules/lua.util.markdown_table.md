# global lua.util.markdown_table








---

## methods
---

### M.split_cells
---
```lua
function M.split_cells(line: string)
 -> cells string[]
 -> prefix string

```

@return `prefix` - Indent and/or blockquote marker, to be replayed





Splits a table row into trimmed cell text, discarding the outer pipes.

Outer pipes are optional in GFM (`a | b` is a table row), so a leading
or trailing empty cell is dropped only when the line actually has the
pipe that produced it.








### M.parse_align
---
```lua
function M.parse_align(cell: string) ->  cgxx.mdtable.Align
```





Reads one delimiter cell's alignment from its colons.








### M.is_delimiter_row
---
```lua
function M.is_delimiter_row(line: string) ->  boolean
```





True if the line is a delimiter row: every cell is dashes, optionally
colon-fenced, and there is at least one cell.








### M.parse
---
```lua
function M.parse(lines: string[]) ->  cgxx.mdtable.Table {
    rows = string[][],
    align = cgxx.mdtable.Align[],
    prefix = string,
}
```





Parses a table's own lines (delimiter row included) into a `Table`.

The delimiter row is deliberately dropped rather than stored: it is
fully described by `align`, and regenerating it on every render is what
reduces "align this column" to a single field assignment.

Rows are padded out to the widest row's cell count, so a table whose
rows disagree (a state you pass through while editing) still round
trips instead of losing cells.








### M.width
---
```lua
function M.width(text: string) ->  integer
```





Width of a cell as it will actually appear on screen.

`strdisplaywidth`, not `#text`: one CJK character is three bytes and
two columns, so a byte count aligns the pipes only for ASCII.








### M.widths
---
```lua
function M.widths(tbl: cgxx.mdtable.Table {
    rows = string[][],
    align = cgxx.mdtable.Align[],
    prefix = string,
}) -> widths integer[]
```





Widest cell per column, floored at `MIN_WIDTH`.








### M.pad
---
```lua
function M.pad(
  text: string,
  width: integer,
  align: cgxx.mdtable.Align
) ->  string
```





Pads cell text to `width` display columns per `align`.

"none" pads like "left": a table has to be a rectangle either way, and
the distinction lives in the delimiter row, not the cells.








### M.render_align
---
```lua
function M.render_align(
  align: cgxx.mdtable.Align,
  width: integer
) ->  string
```





Renders one delimiter cell, `width` display columns wide, so it lines up
with the data cells it sits under.

The colons count toward the width, so the dash run shrinks to make
room for them. `MIN_WIDTH` guarantees at least one dash survives.








### M.render
---
```lua
function M.render(tbl: cgxx.mdtable.Table {
    rows = string[][],
    align = cgxx.mdtable.Align[],
    prefix = string,
}) -> lines string[]
```





Renders a `Table` back to lines, pipes aligned.

Single-space cell padding, outer pipes on every line, and the delimiter
row spaced exactly like a data row: this is prettier's own shape,
verified against its output, so the format-on-save at
`lua/spec/conform.nvim.lua:40` is a no-op on anything rendered here.
Diverging would mean every write silently undid this module's work.








### M.cell_at
---
```lua
function M.cell_at(
  line: string,
  col: integer
)
 -> column integer
 -> offset integer

```
@param `col` - 0-indexed byte column


@return `column` - 1-indexed; clamped into range

@return `offset` - 0-indexed byte offset into the trimmed cell





Locates a byte column within a row: which cell it falls in, and how far
into that cell's trimmed text it sits.

Paired with `M.cell_col` to carry the cursor across a reformat, which
moves every byte column in the line.








### M.cell_col
---
```lua
function M.cell_col(
  line: string,
  column: integer,
  offset: integer
) -> col integer
```
@param `column` - 1-indexed

@param `offset` - 0-indexed byte offset into the trimmed cell


@return `col` - 0-indexed byte column





Inverse of `M.cell_at`: the byte column `offset` bytes into `column`.








### M.in_code_block
---
```lua
function M.in_code_block(
  bufnr: integer,
  row: integer
) ->  boolean
```
@param `row` - 0-indexed






True if `row` sits inside a fenced or indented code block.

This is the one judgement the line scanner below cannot make for
itself, and the reason Tree-sitter is worth consulting even when it
cannot see a table: a pipe table pasted into a ``` fence is not a
table, and Tree-sitter knows that.








### M.is_table_line
---
```lua
function M.is_table_line(line: string) ->  boolean
```





True if the line could be part of a pipe table: it holds an unescaped
pipe and something other than whitespace.








### M.table_range
---
```lua
function M.table_range(
  bufnr: integer,
  row: integer
)
 -> start_row integer?
 -> end_row integer?

```
@param `row` - 0-indexed


@return `start_row` - 0-indexed, inclusive

@return `end_row` - 0-indexed, inclusive





Extent of the table containing `row`, as 0-indexed inclusive rows.

Tree-sitter first: it already excludes tables inside code fences, keeps
`\|` and `` `a|b` `` as cell content, and handles tables indented in a
list or quoted in a blockquote.

It has two blind spots, both straight from GFM's own rules: a table
with no delimiter row yet, and one whose header and delimiter cell
counts disagree, are simply not `pipe_table` nodes. Both are states you
pass through while editing, which is exactly when you want to format.
So fall back to scanning contiguous pipe-bearing lines, gated on
`M.in_code_block` so the single case a naive scanner would corrupt
stays covered.








### M.format
---
```lua
function M.format(
  bufnr: integer?,
  row: integer?
) -> changed boolean
```
@param `bufnr` - Default: current buffer

@param `row` - 0-indexed. Default: the cursor's row






Formats the table containing `row`, leaving the cursor in its own cell.

Writes nothing when the render matches what is already there. That
guard is load-bearing once `M.autocmd` is live: an identical
`nvim_buf_set_lines` still sets 'modified' and still pushes an undo
state, so without it every keystroke-adjacent trigger would litter the
undo tree with no-ops.








### M.format_buffer
---
```lua
function M.format_buffer(bufnr: integer?) -> count integer
```
@param `bufnr` - Default: current buffer


@return `count` - Tables actually rewritten





Formats every pipe table in the buffer.

Back to front, so a table that gains or loses its delimiter row cannot
shift the ranges still queued behind it.








### M.set_align
---
```lua
function M.set_align(
  align: cgxx.mdtable.Align,
  bufnr: integer?
) -> changed boolean
```
@param `bufnr` - Default: current buffer






Sets the alignment of the column under the cursor, then reformats.








### M.enable
---
```lua
function M.enable(bufnr: integer?) ->  nil
```
@param `bufnr` - Default: current buffer






Turns on reformat-as-you-edit for a buffer.








### M.disable
---
```lua
function M.disable(bufnr: integer?) ->  nil
```
@param `bufnr` - Default: current buffer






Turns off reformat-as-you-edit for a buffer.








### M.toggle
---
```lua
function M.toggle(bufnr: integer?) ->  nil
```
@param `bufnr` - Default: current buffer






Flips reformat-as-you-edit for a buffer.








### M.autocmd
---
```lua
function M.autocmd() ->  nil
```





Registers the autocmds that reformat a table as it is edited.

`InsertLeave` and `TextChanged`, deliberately not `CursorMovedI`:
rewriting the line under a moving insert-mode cursor is what makes this
class of feature feel possessed. Together with the no-op guard in
`M.format` these two give tidy tables without fighting the cursor.








### M.keymap
---
```lua
function M.keymap(bufnr: integer?) ->  nil
```
@param `bufnr` - Default: current buffer






Buffer-local keymaps, attached per Markdown buffer by
`filetype.markdown`'s `setup()`.

Buffer-local rather than global because they are only meaningful in
Markdown, and `lua/filetype/init.lua` dispatches one module per
filetype, so `markdown.nex-note` and `markdown.claude` reach this
through `filetype.markdown` rather than by being listed here.








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





`nvim_create_user_command` callback backing `XXMdTable`.








### M.complete
---
```lua
function M.complete() -> actions string[]
```





`nvim_create_user_command` completion for `XXMdTable`.











