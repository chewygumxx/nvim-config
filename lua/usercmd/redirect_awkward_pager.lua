#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- vim: foldlevel=3:foldmethod=expr:

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/usercmd/redirect_awkward_pager.lua
--
--

--
-- Redirect nofile buffer helpers on BANG!
--

local M = {}

-- Redirects output of a given command to a new temporary buffer
local redirect = function(vimcmd, args, bang)
    -- If any arguments were supplied or command NOT executed with "!"
    -- execute command normally
    if args ~= "" or not bang then vim.cmd(vimcmd .. " " .. args) return end

    vim.cmd("enew")
    vim.bo.buftype    = "nofile"
    vim.bo.bufhidden  = "wipe"
    vim.bo.swapfile   = false
    vim.keymap.set("n", "q", "<cmd>bwipeout!<CR>", {
        buffer = true,
        desc = "Quit temp redirect buffer"
    })

    local output = vim.api.nvim_exec2(vimcmd, { output = true }).output
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(output, "\n"))
    vim.cmd("1")
    vim.bo.modifiable = false
    vim.bo.readonly   = true
end


-- vimcmds that print to Neovim's awkward pager
local vimcmds = { "map", "highlight", "autocmd", "command" }

M.command = function(vimcmd)
    return function(opts)
        redirect(vimcmd, opts.args, opts.bang)
    end
end

M.setup = function()
    for _, vimcmd in ipairs(vimcmds) do
        local capitalvcmd, _ = vimcmd:gsub("^%l", string.upper)
        vim.api.nvim_create_user_command("XXRedir" .. capitalvcmd,
            M.command(vimcmd), {
                desc  = "Redirect to temporary buffer (bypass bang!): " .. vimcmd,
                nargs = "*",
                bang  = true
        })
        -- Only abbreviate when vimcmd is in the command position and is
        -- invoked as the command itself
        vim.cmd(("cnoreabbrev <expr> %s (getcmdtype() == ':' && getcmdline() == '%s') ? 'XXRedir%s' : '%s'")
            :format(vimcmd, vimcmd, capitalvcmd, vimcmd))   
    end
end

return M
