#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- vim: foldlevel=3:foldmethod=expr:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/usercmd/interpret_escape.lua
--
--

--
-- Translate and interpret the escape codes of current buffer
--

local M = {}

--- Writes lines, before ANSI translation, to a timestamped file under
--- `stdpath("cache") .. "/log-ansi/"`, named after the current buffer.
---@param lines string[]
---@return nil
local save_preinterpreted_copy = function(lines)
    -- Save Directory
    local log_dir = vim.fn.stdpath("cache") .. "/log-ansi/"
    if not vim.fn.isdirectory(log_dir) then vim.fn.mkdir(log_dir, "p") end

    -- If filename has a tail, remove it.
    -- Irrespective of whether filename had tail or not, append '.ansi'.
    -- Awkward if no head
    local filename = vim.fn.expand("%:t"):gsub("^(.-)(%.[^%.]*)$", "%1")
        .. ".ansi"

    -- Write
    local handle = io.open(log_dir .. filename, "w+")
    if not handle then
        vim.notify("Failed to create file handle to: " .. log_dir .. filename)
        return
    end
    handle:write(table.concat(lines, "\r\n"))
    handle:flush()
    handle:close()
end

--- `gsub` replacement callback: expands a chained truecolour SGR
--- parameter capture into a standalone CSI sequence.
---@param params string Captured "n:2::r:g:b" parameter chunk
---@return string sequence Standalone "\027[n;2;r;g;bm" replacement
local expand_chained_truecolour_params = function(params)
    local out = params:gsub("(%d+):2::(%d+):(%d+):(%d+)", "%1;2;%2;%3;%4")
    return "\027[" .. out .. "m"
end

--- Expands chained truecolour SGR params in every line.
---@param lines string[]
---@return string[] lines
local translate_ansi_colons = function(lines)
    -- For future me when this breaks
    --
    -- Chained parameters in a single sequence, something like
    -- \e[1;38:2::15:225:146m (bold + truecolour in one CSI sequence), won't
    -- match because the outer pattern requires the entire parameter string to
    -- be the truecolour form. This is probably the most realistic gap depending
    -- on what's generating the escape codes. If you want to handle it, I'd need
    -- to match within a broader CSI sequence and substitute only the matching
    -- subportion, which complicates things considerably. Worth checking whether
    -- the actual input ever chains parameters like that before investing in it.
    return vim.tbl_map(function(line)
        line = line:gsub(
            "\027%[([%d]+:2::[%d]+:[%d]+:[%d]+)m",
            expand_chained_truecolour_params
        )
        return line
    end, lines)
end

--- Re-renders the current buffer's raw escape codes in a terminal buffer.
---@param bang? boolean Skip writing the pre-interpreted backup copy
---@return nil
local interpret_escape = function(bang)
    bang = bang or false

    vim.wo.number         = false           -- < Prepare window of equivalent
    vim.wo.relativenumber = false           -- < columns to source
    vim.wo.statuscolumn   = ""              -- <
    vim.wo.signcolumn     = "no"            -- <
    vim.opt.listchars     = { space = " " } -- :h list

    -- Omit empty lines. Trim whitespace, and other characters from both start
    -- and end of line. :h trim()
    local bufnr = 0
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    while #lines > 0 and vim.trim(lines[#lines]) == "" do
        lines[#lines] = nil
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})

    -- Unless command was invoked with bang, write original buffer content, with
    -- escape codes pre-interpreted, to a dedicated 'log-ansi/' directory under
    -- stdpath('cache')
    if bang == false then
        save_preinterpreted_copy(lines)
    end

    lines = translate_ansi_colons(lines)

    vim.api.nvim_chan_send(
        vim.api.nvim_open_term(bufnr, {}),
        table.concat(lines, "\r\n")
    )
    vim.keymap.set("n", "q", "<cmd>qa!<cr>", { buffer = bufnr, silent = true })
    vim.api.nvim_create_autocmd("TextChanged", {
        buffer = bufnr,
        command = "normal! G$",
    })
    vim.api.nvim_create_autocmd("TermEnter", {
        buffer = bufnr,
        command = "stopinsert",
    })
end

--- `XXInterpretEscape` callback.
---@param opts vim.api.keyset.create_user_command.command_args
---@return nil
M.command = function(opts)
    interpret_escape(opts.bang)
end

--- Registers the `XXInterpretEscape` user command.
---@return nil
M.setup = function()
    vim.api.nvim_create_user_command("XXInterpretEscape", M.command, {
        desc = "Translate and interpret escape codes in terminal buffer",
        bang = true,
    })
end

return M
