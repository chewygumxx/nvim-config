#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- vim: foldlevel=3:foldmethod=expr:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/usercmd/interpret_escape.lua
--
--

--
-- Translate and interpret the escape codes of current buffer
--

local M = {}

local save_preinterpreted_copy = function(lines)
    -- Save Directory 
    local log_dir = vim.fn.stdpath("cache") .. "/log-ansi/"
    if not vim.fn.isdirectory(log_dir) then vim.fn.mkdir(log_dir, "p") end

    -- If filename has a tail, remove it.
    -- Irrespective of whether filename had tail or not, append '.ansi'.
    -- Awkward if no head
    local filename = vim.fn.expand("%:t"):gsub("^(.-)(%.[^%.]*)$", "%1") .. ".ansi"

    -- Write
    local handle  = io.open(log_dir .. filename, "wc+")
    handle:write(table.concat(lines, "\r\n"))
    handle:flush()
    handle:close()
end

local translate_ansi_colons = function(lines)
    -- For future me when this breaks 
    --
    -- Chained parameters in a single sequence — something like \e[1;38:2::15:225:146m
    -- (bold + truecolour in one CSI sequence) won't match because the outer pattern
    -- requires the entire parameter string to be the truecolour form. This is probably
    -- the most realistic gap depending on what's generating the escape codes. If you
    -- want to handle it, I'd need to match within a broader CSI sequence and substitute
    -- only the matching subportion, which complicates things considerably. Worth checking
    -- whether the actual input ever chains parameters like that before investing in it.
    return vim.tbl_map(function(line)
      line = line:gsub("\027%[([%d]+:2::[%d]+:[%d]+:[%d]+)m", function(params)
          local out = params:gsub("(%d+):2::(%d+):(%d+):(%d+)", "%1;2;%2;%3;%4")
          return "\027[" .. out .. "m"
      end)
      return line

    end, lines)
end

local interpret_escape = function(bang)
    bang = bang or false

    vim.wo.number = false               -- < Prepare buffer of equivalent columns to source
    vim.wo.relativenumber = false       -- <
    vim.wo.statuscolumn = ""            -- <
    vim.wo.signcolumn = "no"            -- <
    vim.opt.listchars = { space = " " } -- :h list

    -- Omit empty lines. Trim whitespace, and other characters from both start and end of line.
    -- :h trim()
    local bufnr = 0 --vim.api.nvim_get_current_buf()
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
  
    vim.api.nvim_chan_send(vim.api.nvim_open_term(bufnr, {}), table.concat(lines, "\r\n"))
    vim.keymap.set("n", "q", "<cmd>qa!<cr>",   { buffer = bufnr, silent  = true })
    vim.api.nvim_create_autocmd("TextChanged", { buffer = bufnr, command = "normal! G$" })
    vim.api.nvim_create_autocmd("TermEnter",   { buffer = bufnr, command = "stopinsert" })
end

M.command = function(opts)
    interpret_escape(opts.bang)
end 

M.setup = function()
    vim.api.nvim_create_user_command("XXInterpretEscape", M.command, {
        desc = "Translate and interpret escape codes in terminal buffer",
        bang = true,
    })
end

return M
