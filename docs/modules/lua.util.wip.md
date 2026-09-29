# global lua.util.wip








---

## methods
---

### M.snapshot
---
```lua
function M.snapshot(
  bufnr: integer?,
  report: boolean?
) ->  nil
```
@param `bufnr` - Default: current buffer

@param `report` - Notify on no-ops and ineligibility too






Commits bufnr's current text onto `refs/wip/<branch>`.








### M.enable
---
```lua
function M.enable(bufnr: integer?) ->  nil
```
@param `bufnr` - Default: current buffer






Enables WIP snapshots for bufnr.








### M.disable
---
```lua
function M.disable(bufnr: integer?) ->  nil
```
@param `bufnr` - Default: current buffer






Disables WIP snapshots for bufnr, dropping any pending debounce.








### M.toggle
---
```lua
function M.toggle(bufnr: integer?) ->  nil
```
@param `bufnr` - Default: current buffer






Toggles WIP snapshots for bufnr.








### M.drop
---
```lua
function M.drop() ->  nil
```





Deletes the WIP ref of the branch the current buffer's repository is
on. Destructive, hence bang-only.








### M.autocmd
---
```lua
function M.autocmd() ->  nil
```





Registers this module's autocmds in the "cgxx.wip" augroup.








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





`nvim_create_user_command` callback backing `XXWip`.








### M.complete
---
```lua
function M.complete() -> actions string[]
```





`nvim_create_user_command` completion for `XXWip`.











## fields
---

### M.debounce
---
```lua
M.debounce : integer
```



Idle time in milliseconds, after a change, before a snapshot is taken.








### M.timeout
---
```lua
M.timeout : integer
```



Milliseconds any one `git` call may take. `util.git.info` bounds its
own for the same reason: a hung git on a network filesystem would
otherwise never call back, or, for the two `locate` lookups that
block, never return.









