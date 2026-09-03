#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/filetype/man.lua
--
--

-- 
-- Filetype-specific configuration for manpages
--

local M = {}

local options = {
    number = true,
}

M.autocmd = function()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "man",
        desc  = "Filetype specialised module: manpages",
        group = vim.api.nvim_create_augroup("cgxx.filetype_manpages", { clear = true }),
        callback = function(opts)
            M.setup(opts.file, opts.buf)
        end,
    })
end

M.setup = function(file, buf) -- Argument 'file' is a placeholder for now
    file = file or vim.fn.expand("%")
    buf  = buf  or 0

    for opt, value in pairs(options) do
        vim.o[opt] = value
    end
end

return M
