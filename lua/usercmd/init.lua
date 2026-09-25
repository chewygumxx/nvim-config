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
    local vt   = require("util.visual_traversal").command
    usercmd("XXVisTrav", assert(vt("toggle")), { desc = "Toggle: " .. desc })
    usercmd("XXVisTravToggle", assert(vt("toggle")), {
        desc = "Toggle: " .. desc,
    })
    usercmd("XXVisTravEnable", assert(vt("enable")), {
        desc = "Enable: " .. desc,
    })
    usercmd("XXVisTravDisable", assert(vt("disable")), {
        desc = "Disable: " .. desc,
    })
end

--- Registers the `XXInterpretEscape` user command.
---@return nil
local interpret_escape = function()
    local desc = "Translate and interpret escape codes in terminal buffer"
    local ie   = require("usercmd.interpret_escape")
    usercmd("XXInterpretEscape", ie.command, { desc = desc, bang = true })
end

--- Registers the `XXRedir*` user commands and their cnoreabbrevs.
---@return nil
local redirect_awkward_pager = function()
    local desc    = "Redirect to temporary buffer (bypass bang!): "
    local vimcmds = { "autocmd", "command", "highlight", "map" }
    local rap     = require("usercmd.redirect_awkward_pager").command
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
    local ih   = require("util.header")
    usercmd("XXInsertHeader", ih.command, { desc = desc })
end

--- Registers the `XXLuaChecker` user command, backed by
--- `usercmd.lua_checker`/`util.lua_checker`.
---@return nil
local lua_checker = function()
    local desc = "Switch nvim-lint's lua type checker "
        .. "(luals_check/emmylua_check); bare toggles"
    local mod  = require("usercmd.lua_checker")
    usercmd("XXLuaChecker", mod.command, {
        desc = desc,
        nargs = "?",
        complete = mod.complete,
    })
end

--- Registers the `XXWip` user command, backed by `util.wip`.
---@return nil
local wip = function()
    local desc = "WIP snapshots to refs/wip/<branch> "
        .. "(toggle/enable/disable/snapshot/drop); bare toggles"
    local mod  = require("util.wip")
    usercmd("XXWip", mod.command, {
        desc     = desc,
        nargs    = "?",
        bang     = true,
        complete = mod.complete,
    })
end

--- Registers every user command this config defines.
---@return nil
M.setup = function()
    visual_traversal()
    interpret_escape()
    redirect_awkward_pager()
    insert_header()
    lua_checker()
    wip()
end

return M
