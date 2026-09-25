#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/claude.lua
--
--

--
-- Helpers for buffers opened by Claude Code CLI's external-editor bridge
-- (`ctrl+e`/`chat:externalEditor`), used for prompt composition. The CLI
-- writes `claude-prompt-<hash>.md` under a shared `claude-<uid>` directory
-- in the OS temp dir, and unlinks it again once the editor exits.
-- `lua/filetype/init.lua` resolves these to the compound filetype
-- `markdown.claude` (see its `pattern` table), which is this module's
-- resolution heuristic.
--

local M = {}

--- Full-path pattern (for `vim.filetype.add`) matching Claude Code CLI's
--- external-editor temp file. `vim.filetype.add` implicitly anchors
--- user-supplied patterns with `^...$`, so this must NOT have a trailing
--- `$` of its own (a second, non-final `$` is just a literal dollar sign
--- in a Lua pattern, so it would never match).
---@type string
M.prompt_path_pattern = ".*/claude%-prompt%-.-%.md"

--- Substring marking the divider line between Claude's last response
--- (quoted above it, one leading "# " per line) and the reply being
--- composed below. Only present when "Show last response in external
--- editor" is enabled in `/config`.
---@type string
M.reply_divider = "Write your reply below this line"

--- Whether buffer `bufnr` was resolved to the `markdown.claude` compound
--- filetype.
---@param bufnr? integer (default: current buffer)
---@return boolean
M.is_prompt_buffer = function(bufnr)
    local ft = vim.bo[bufnr or 0].filetype
    return ft == "claude" or ft:sub(-7) == ".claude"
end

--- Finds the 1-indexed line number of the last-response divider in buffer
--- `bufnr`, if present.
---@param bufnr? integer (default: current buffer)
---@return integer? lnum
M.reply_divider_line = function(bufnr)
    bufnr = bufnr or 0
    for lnum, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        if line:find(M.reply_divider, 1, true) then
            return lnum
        end
    end
    return nil
end

--- Folds a Claude prompt buffer's quoted last-response context (lines 1
--- through its divider, if any) closed in the current window. Uses
--- `foldmethod=manual` rather than `foldexpr`: this buffer's context block
--- is one leading "# " per line, which would otherwise parse as a run of
--- ATX headings under `nvim-treesitter`'s own (`FileType`- and
--- async-parser-install-triggered) `foldexpr`, and manual folds are
--- immune to whichever of the two last set `foldexpr`.
---
--- Runs on every `BufWinEnter` rather than once at `FileType`, since folds
--- are window-local: without this, a second split (or a buffer revisited
--- without a fresh `FileType` event) would show no fold at all.
---@param bufnr integer
---@return nil
M.setup_fold_window = function(bufnr)
    if not M.is_prompt_buffer(bufnr) then
        return
    end

    local divider = M.reply_divider_line(bufnr)
    if not divider then
        return
    end

    vim.wo.foldmethod = "manual"
    vim.cmd(("silent! 1,%dfold"):format(divider))
end

--- Registers the `BufWinEnter` autocmd that (re-)applies the fold above
--- for Claude prompt buffers in every window that displays one.
---@return nil
M.autocmd = function()
    vim.api.nvim_create_autocmd("BufWinEnter", {
        desc     = "Fold Claude Code's last-response context, if present",
        group    = vim.api.nvim_create_augroup("cgxx.claude", {
            clear = true,
        }),
        callback = function(opts)
            M.setup_fold_window(opts.buf)
        end,
    })
end

return M
