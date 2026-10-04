#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/agentprompt.lua
--
--

--
-- Filetype-specific configuration for the `markdown.agentprompt` compound
-- filetype: Claude Code CLI's external-editor prompt-composition buffers
--

local M = {}

local markdown = require("filetype.markdown")

-- A copy rather than the table itself, which `filetype.nex_note` aliases:
-- assigning into an alias would hand every Markdown buffer this width
M.local_opts   = vim.tbl_extend("force", markdown.local_opts, {
    textwidth = 80,
})
M.hlgroup_defs = markdown.hlgroup_defs

--- Moves the cursor past the last-response divider line (if present, see
--- `util.agentprompt`), to where the reply is actually composed. The fold
--- itself is applied per-window by `util.agentprompt`'s `BufWinEnter` autocmd,
--- since folds don't carry over between windows on the same buffer.
---@param opts vim.api.keyset.create_autocmd.callback_args
---@return nil
M.setup = function(opts)
    -- Before the early return below: a prompt buffer with no divider is
    -- still Markdown, and should still get the table keymaps.
    markdown.setup(opts)

    if not require("util.agentprompt").reply_divider_line(opts.buf) then
        return
    end

    vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(opts.buf), 0 })
end

return M
