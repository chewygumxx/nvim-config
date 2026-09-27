# global lua.keymap








---

## methods
---

### M.clear_hlsearch
---
```lua
function M.clear_hlsearch(
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>h"

@param `desc` - Default: ":noh - Clear highlight of search match"






Maps lhs to `:noh` (clear search highlight).








### M.toggle_relativenumber
---
```lua
function M.toggle_relativenumber(
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>rn"

@param `desc` - Default: "Toggle relativenumber"






Maps lhs to toggle `relativenumber` persistently.








### M.blink_relativenumber
---
```lua
function M.blink_relativenumber(
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>nn"

@param `desc` - Default: "Blink relativenumber"






Maps lhs to flip `relativenumber` for 2 seconds, then restore it.








### M.blink_linenumber
---
```lua
function M.blink_linenumber(
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>ln"

@param `desc` - Default: "Blink line number in gutter"






Maps lhs to highlight the absolute line number gutter as `ErrorMsg`
for 3 seconds, then restore `number`/`relativenumber`/`LineNr`.








### M.format_buffer
---
```lua
function M.format_buffer(
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>tw"

@param `desc` - Default: "Format buffer line wrapping according to
  textwidth"






Maps lhs to reflow the whole buffer at `textwidth` (`gggqG`).








### M.inspect
---
```lua
function M.inspect(
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>in"

@param `desc` - Default: ":Inspect highlight groups under cursor"






Maps lhs to `:Inspect` (highlight groups under cursor).








### M.reload_foldmethod
---
```lua
function M.reload_foldmethod(
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>rf"

@param `desc` - Default: "Reload foldmethod"






Maps lhs to re-trigger fold recomputation by re-assigning `foldmethod`
to itself.








### M.scroll_distance
---
```lua
function M.scroll_distance(
  count: integer?,
  down: string?,
  up: string?
) ->  nil
```
@param `count` - Default: 5

@param `down` - Default: "<C-d>"

@param `up` - Default: "<C-u>"






Maps down/up to scroll `count` lines rather than half a window.

The count is carried on the keys rather than set as an option, because
'scroll' is window local and Neovim recomputes it to half the window
height on every resize; `lua/option/view.lua` says the same from the
other side. A count given to CTRL-D or CTRL-U sets 'scroll' to it, so
re-issuing it on each press is what makes the distance stick.

Mode is normal and visual only, never insert: `lua/spec/mkdnflow.lua`
binds insert-mode "<C-d>" to `MkdnDedentListItem`.

`expr` rather than a plain right-hand side, because Vim prefixes a
typed count onto the result: "5<C-d>" would turn "10<C-d>" into
"105<C-d>". Returning the count only when `vim.v.count` is zero leaves
an explicit one working.








### M.visual_indent_persist
---
```lua
function M.visual_indent_persist(
  indent: string?,
  dedent: string?,
  desc: string?
) ->  nil
```
@param `indent` - Default: ">"

@param `dedent` - Default: "<"

@param `desc` - Default: "Remain in visual mode after indenting"






Maps indent/dedent in visual mode to reselect afterward (">gv"/"<gv"),
instead of exiting visual mode.








### M.file_goto
---
```lua
function M.file_goto(
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "gf"

@param `desc` - Default: "Open file and if provided, go to line
  number"






Maps lhs to native "gF" (goto file, honouring a trailing line number).








### M.file_create_or_open
---
```lua
function M.file_create_or_open(
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "gF"

@param `desc` - Default: "Create or open new file according to
  path under cursor"






Maps lhs to create or open the file under cursor (`:e <cfile>`).








### M.blackhole_register
---
```lua
function M.blackhole_register() ->  nil
```





Routes single-character deletion ("x") and visual paste-over ("p")
through the blackhole register, so they don't clobber the unnamed
register.








### M.setup
---
```lua
function M.setup() ->  nil
```





Registers every keymap this config defines.











