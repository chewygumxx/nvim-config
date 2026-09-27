# global lua.usercmd.lua_checker








---

## methods
---

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





`XXLuaChecker` callback: sets the active lua type checker to
opts.fargs[1], or toggles to the next one if called bare.








### M.complete
---
```lua
function M.complete() ->  string[]
```





Completion candidates for `XXLuaChecker`'s single argument.











