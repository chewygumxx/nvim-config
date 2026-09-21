#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- vim: foldlevel=3:foldmethod=expr:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/visual_traversal.lua
--
--

--
-- Buffer local keymap settings for visual navigation/traversal
--

local M = {}

local traversal_keymaps = { "j", "k", "0", "$" }

--- Re-applies the traversal keymaps for bufnr's current enabled state.
---@param bufnr? integer Default: current buffer
---@return nil
local update_keymaps = function(bufnr)
    bufnr         = bufnr or 0
    local enabled = vim.b[bufnr].cgxx_visual_traversal
    local status  = "Visual Traversal: " .. (enabled and "ON" or "OFF")

    for _, key in ipairs(traversal_keymaps) do
        vim.keymap.set({ "n", "v" }, key, (enabled and "g" .. key or key), {
            buf   = bufnr,
            remap = false,
            desc  = status,
        })
    end

    if vim.g.cgxx_verbose then
        vim.print(status)
    end
end

--- Enables visual traversal keymaps ("gj"/"gk"/"g0"/"g$" style motion)
--- in bufnr.
---@param bufnr? integer Default: current buffer
---@return nil
M.enable = function(bufnr)
    bufnr                              = bufnr or 0
    vim.b[bufnr].cgxx_visual_traversal = true
    update_keymaps(bufnr)
end

--- Disables visual traversal keymaps in bufnr, restoring plain motion.
---@param bufnr? integer Default: current buffer
---@return nil
M.disable = function(bufnr)
    bufnr                              = bufnr or 0
    vim.b[bufnr].cgxx_visual_traversal = false
    update_keymaps(bufnr)
end

--- Toggles visual traversal keymaps in bufnr.
---@param bufnr? integer Default: current buffer
---@return nil
M.toggle = function(bufnr)
    bufnr                              = bufnr or 0
    vim.b[bufnr].cgxx_visual_traversal = not vim.b[bufnr].cgxx_visual_traversal
    update_keymaps(bufnr)
end

---@type table<string, fun(opts: vim.api.keyset.create_user_command.command_args)>
local act_func = {
    toggle  = function(_)
        M.toggle()
    end,
    enable  = function(_)
        M.enable()
    end,
    disable = function(_)
        M.disable()
    end,
}

--- Resolves act to a `nvim_create_user_command` callback.
---@param act string
---@return fun(opts: vim.api.keyset.create_user_command.command_args)? callback nil if act isn't a known action
M.command = function(act)
    return act_func[act]
end

return M
