# global lua.usercmd.redirect_awkward_pager








---

## methods
---

### M.command
---
```lua
function M.command(vimcmd: string) -> callback fun(opts: vim.api.keyset.create_user_command.command_args)
```
@param `vimcmd` - Vim command to redirect (no leading ":")






Builds an `XXRedir*` user command callback bound to vimcmd.











