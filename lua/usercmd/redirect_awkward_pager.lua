#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- vim: foldlevel=3:foldmethod=expr:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/usercmd/redirect_awkward_pager.lua
--
--

--
-- Redirect nofile buffer helpers on BANG!
--

local M = {}

--- Redirects the output of vimcmd to a new temporary buffer, unless args
--- were supplied or vimcmd wasn't invoked with a bang (then run normally).
---@param vimcmd string  Vim command to execute (no leading ":")
---@param args   string  Command arguments, as passed through by the wrapping
---  user command
---@param bang   boolean Whether the wrapping user command had a bang
---@return nil
local redirect = function(vimcmd, args, bang)
    -- If any arguments were supplied or command NOT executed with "!"
    -- execute command normally
    if args ~= "" or not bang then
        vim.cmd(vimcmd .. " " .. args)
        return
    end

    vim.cmd("enew")
    vim.bo.buftype   = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile  = false
    vim.keymap.set("n", "q", "<cmd>bwipeout!<CR>", {
        buffer = true,
        desc = "Quit temp redirect buffer",
    })

    local output = vim.api.nvim_exec2(vimcmd, { output = true })
        .output
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(output, "\n"))
    vim.cmd("1")
    vim.bo.modifiable = false
    vim.bo.readonly   = true
end

-- vimcmds that print to Neovim's awkward pager
local vimcmds = { "map", "highlight", "autocmd", "command" }

--- Builds an `XXRedir*` user command callback bound to vimcmd.
---@param vimcmd string Vim command to redirect (no leading ":")
---@return fun(opts: vim.api.keyset.create_user_command.command_args) callback
M.command = function(vimcmd)
    return function(opts)
        redirect(vimcmd, opts.args, opts.bang)
    end
end

--- Registers an `XXRedir*` user command, and its bang-only cnoreabbrev,
--- for every entry in vimcmds.
---@return nil
M.setup = function()
    for _, vimcmd in ipairs(vimcmds) do
        local capitalvcmd, _ = vimcmd:gsub("^%l", string.upper)
        vim.api.nvim_create_user_command("XXRedir" .. capitalvcmd, M.command(
            vimcmd
        ), {
            desc  = "Redirect to temporary buffer (bypass bang!): " .. vimcmd,
            nargs = "*",
            bang  = true,
        })
        -- Only abbreviate when vimcmd is in the command position and is
        -- invoked as the command itself
        vim.cmd(
            ("cnoreabbrev <expr> %s (getcmdtype() == ':' && getcmdline() == '%s') ? 'XXRedir%s' : '%s'")
                :format(vimcmd, vimcmd, capitalvcmd, vimcmd)
        )
    end
end

return M
