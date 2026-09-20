#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/usercmd/init.lua
--
--

--
-- Authoritative user command creation and definition
--

local M = {}

local usercmd = vim.api.nvim_create_user_command

--- Registers the `XXVisTrav*` user commands, backed by
--- `util.visual_traversal`.
---@return nil
local visual_traversal = function()
    local desc = "Visual traversal in current buffer"
    local mod  = _G.require_guard("util.visual_traversal")
    if not mod then
        return
    end
    local vt = mod.command
    usercmd("XXVisTrav", vt("toggle"), { desc = "Toggle: " .. desc })
    usercmd("XXVisTravToggle", vt("toggle"), { desc = "Toggle: " .. desc })
    usercmd("XXVisTravEnable", vt("enable"), { desc = "Enable: " .. desc })
    usercmd("XXVisTravDisable", vt("disable"), { desc = "Disable: " .. desc })
end

--- Registers the `XXInterpretEscape` user command.
---@return nil
local interpret_escape = function()
    local desc = "Translate and interpret escape codes in terminal buffer"
    local ie   = _G.require_guard("usercmd.interpret_escape")
    if not ie then
        return
    end
    usercmd("XXInterpretEscape", ie.command, { desc = desc, bang = true })
end

--- Registers the `XXRedir*` user commands and their cnoreabbrevs.
---@return nil
local redirect_awkward_pager = function()
    local desc    = "Redirect to temporary buffer (bypass bang!): "
    local vimcmds = { "autocmd", "command", "highlight", "map" }
    local mod     = _G.require_guard("usercmd.redirect_awkward_pager")
    if not mod then
        return
    end
    local rap = mod.command
    for _, vimcmd in ipairs(vimcmds) do
        local capitalvcmd, _ = vimcmd:gsub("^%l", string.upper)
        usercmd("XXRedir" .. capitalvcmd, rap(vimcmd), {
            desc  = desc .. vimcmd,
            nargs = "*",
            bang  = true,
        })
        -- Only abbreviate when vimcmd is in the command position and is
        -- invoked as the command itself
        vim.cmd(
            ("cnoreabbrev <expr> %s (getcmdtype() == ':'"
                .. "&& getcmdline() == '%s') ? 'XXRedir%s' : '%s'")
                :format(vimcmd, vimcmd, capitalvcmd, vimcmd)
        )
    end
end

--- Registers the `XXInsertHeader` user command.
---@return nil
local insert_header = function()
    local desc = "Prepend buffer with a header, "
        .. "templated according to filepath and extension."
    local ih   = _G.require_guard("util.header")
    if not ih then
        return
    end
    usercmd("XXInsertHeader", ih.command, { desc = desc })
end

--- Registers every user command this config defines.
---@return nil
M.setup = function()
    visual_traversal()
    interpret_escape()
    redirect_awkward_pager()
    insert_header()
end

return M
