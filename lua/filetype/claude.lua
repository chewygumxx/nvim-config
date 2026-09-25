#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/claude.lua
--
--

--
-- Filetype-specific configuration for the `markdown.claude` compound
-- filetype: Claude Code CLI's external-editor prompt-composition buffers
--

local M = {}

local markdown = require("filetype.markdown")

M.local_opts   = markdown.local_opts
M.hlgroup_defs = markdown.hlgroup_defs

--- Moves the cursor past the last-response divider line (if present, see
--- `util.claude`), to where the reply is actually composed. The fold
--- itself is applied per-window by `util.claude`'s `BufWinEnter` autocmd,
--- since folds don't carry over between windows on the same buffer.
---@param opts vim.api.keyset.create_autocmd.callback_args
---@return nil
M.setup = function(opts)
    if not require("util.claude").reply_divider_line(opts.buf) then
        return
    end

    vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(opts.buf), 0 })
end

return M
