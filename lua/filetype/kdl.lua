#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/filetype/kdl.lua
--
--

--
-- KDL filetype settings
--

local M = {}

local opts = {
}

local hlgroup_defs = {
    ["@type"]                  = { link = "@property" },
    ["@punctuation.bracket"]   = { link = "PreProc"   },
    ["@punctuation.delimiter"] = { link = "Macro"     },
}

M.autocmd = function()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "kdl",
        desc  = "Filetype specialised module: Markdown",
        group = vim.api.nvim_create_augroup("cgxx.filetype_markdown", { clear = true }),
        callback = function(opts)
            M.setup(opts.file, opts.buf)
        end,
    })
end

M.setup = function(file, buf)
    file = file or vim.fn.expand("%")
    buf  = buf  or 0

    for opt, value in pairs(opts) do
        vim.api.nvim_set_option_value(opt, value, { buf = buf })
    end
    for hlgroup, defmap in pairs(hlgroup_defs) do
        vim.api.nvim_set_hl(0, hlgroup .. ".kdl", defmap)
    end
end

return M
