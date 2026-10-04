# global lua.util.agentprompt








---

## methods
---

### M.is_prompt_buffer
---
```lua
function M.is_prompt_buffer(bufnr: integer?) ->  boolean
```
@param `bufnr` - (default: current buffer)






Whether buffer `bufnr` was resolved to the `markdown.agentprompt` compound
filetype.








### M.reply_divider_line
---
```lua
function M.reply_divider_line(bufnr: integer?) -> lnum integer?
```
@param `bufnr` - (default: current buffer)






Finds the 1-indexed line number of the last-response divider in buffer
`bufnr`, if present.








### M.setup_fold_window
---
```lua
function M.setup_fold_window(bufnr: integer) ->  nil
```





Folds a Claude prompt buffer's quoted last-response context (lines 1
through its divider, if any) closed in the current window. Uses
`foldmethod=manual` rather than `foldexpr`: this buffer's context block
is one leading "# " per line, which would otherwise parse as a run of
ATX headings under `nvim-treesitter`'s own (`FileType`- and
async-parser-install-triggered) `foldexpr`, and manual folds are
immune to whichever of the two last set `foldexpr`.

Runs on every `BufWinEnter` rather than once at `FileType`, since folds
are window-local: without this, a second split (or a buffer revisited
without a fresh `FileType` event) would show no fold at all.








### M.autocmd
---
```lua
function M.autocmd() ->  nil
```





Registers the `BufWinEnter` autocmd that (re-)applies the fold above
for Claude prompt buffers in every window that displays one.











## fields
---

### M.prompt_path_pattern
---
```lua
M.prompt_path_pattern : string
```



Full-path pattern (for `vim.filetype.add`) matching Claude Code CLI's
external-editor temp file. `vim.filetype.add` implicitly anchors
user-supplied patterns with `^...$`, so this must NOT have a trailing
`$` of its own (a second, non-final `$` is just a literal dollar sign
in a Lua pattern, so it would never match).








### M.reply_divider
---
```lua
M.reply_divider : string
```



Substring marking the divider line between Claude's last response
(quoted above it, one leading "# " per line) and the reply being
composed below. Only present when "Show last response in external
editor" is enabled in `/config`.









