# global lua.util.visual_traversal








---

## methods
---

### M.enable
---
```lua
function M.enable(bufnr: integer?) ->  nil
```
@param `bufnr` - Default: current buffer






Enables visual traversal keymaps ("gj"/"gk"/"g0"/"g$" style motion)
in bufnr.








### M.disable
---
```lua
function M.disable(bufnr: integer?) ->  nil
```
@param `bufnr` - Default: current buffer






Disables visual traversal keymaps in bufnr, restoring plain motion.








### M.toggle
---
```lua
function M.toggle(bufnr: integer?) ->  nil
```
@param `bufnr` - Default: current buffer






Toggles visual traversal keymaps in bufnr.








### M.command
---
```lua
function M.command(act: string) -> callback (fun(opts: vim.api.keyset.create_user_command.command_args))?
```

@return `callback` - nil if act isn't a known action





Resolves act to a `nvim_create_user_command` callback.











