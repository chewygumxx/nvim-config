#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/dot_config/nvim/lua/util/header.lua
--
--

--
-- Immutable header text for all text file formats
--

local M = {}

local util_modeline = _G.require_guard("util.modeline")
local util_shebang  = _G.require_guard("util.shebang")
local util_git      = _G.require_guard("util.git")


local trim_lines = function(lines)
    for i=1,#lines,1 do
        lines[i] = lines[i]:gsub("[ \t]+$", "")
    end
    return lines
end

M.insert = function(file, buf, opt)
    if not (util_modeline and util_shebang and util_git) then
        return
    end

    local file = file or vim.fn.expand("%")
    local buf  = buf  or 0
    local opt  = opt  or {}
    local commentstring = opt.commentstring or vim.bo[buf].commentstring

    if commentstring == "" then
        return
    end

    -- Modeline
    local lines = {}
    if vim.bo[buf].filetype == "markdown" then
        -- Markdown Frontmatter Start
        commentstring = "# %s"
        lines[#lines + 1] = "---"
        lines[#lines + 1] = util_modeline.base({
            et = true,
            sw = 2,
            ft = "markdown",
            commentstring = commentstring
        })
    else
        lines[#lines + 1] = util_shebang.get(file, buf)
        lines[#lines + 1] = util_modeline.base({
            et = true,
            sw = 4,
            ft = vim.bo[buf].filetype,
            commentstring = commentstring
        })
    end

    -- License
    lines[#lines + 1] = string.format(commentstring, "SPDX-License-Identifier: GPL-3.0-only")

    -- (Slug and) Path
    local slug
    local path = util_git.path(file)
    if path:find(":", 1, true) == 1 then
        slug = util_git.slug(file)
    end
    if path:find("~/.config", 1, true) == 1 then
        slug = "chewygumxx/dotfiles"
        path, _ = path:gsub("~/%.config", ":/dot_config")
    end

    if path then
        lines[#lines + 1] = ""
        lines[#lines + 1] = string.format(commentstring, "")
        lines[#lines + 1] = string.format(commentstring, "")
        if slug then
            lines[#lines + 1] = string.format(commentstring, "~" .. slug .. ".git")
            lines[#lines + 1] = string.format(commentstring, "::: " .. path)
        else
            lines[#lines + 1] = string.format(commentstring, path)
        end
        lines[#lines + 1] = string.format(commentstring, "")
        lines[#lines + 1] = string.format(commentstring, "")
    end
 
    -- Markdown Frontmatter End
    if vim.bo[buf].filetype == "markdown" then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "ctime: " .. os.date("%Y-%m-%d")
        lines[#lines + 1] = "title: XXTITLE"
        lines[#lines + 1] = "tags:  [  ]"
        lines[#lines + 1] = "---"
        lines[#lines + 1] = ""
        lines[#lines + 1] = "# XXTITLE"
    end
    
    lines[#lines + 1] = ""

    vim.api.nvim_buf_set_lines(buf, 0, 0, false, trim_lines(lines))
end



M.command = function()
    M.insert(vim.fn.expand("%"), vim.api.nvim_get_current_buf())
end

M.autocmd = function()
    vim.api.nvim_create_autocmd("BufNewFile", {
        group = vim.api.nvim_create_augroup("cgxx.header_mark_pending", { clear = true }),
        desc  = "Designates new file buffer for pending header insertion.",
        callback = function(opts)
            vim.b[opts.buf].cgxx_pending_header = true
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("cgxx.header_apply_insert", { clear = true }),
        desc  = "Inserts templated header into new file buffer once filetype is known.",
        callback = function(opts)
            if  vim.b[opts.buf].cgxx_pending_header then
                vim.b[opts.buf].cgxx_pending_header = nil
                M.insert(opts.file, opts.buf)
            end
        end,
    })
end

M.setup = function()
    vim.api.nvim_create_user_command("XXInsertHeader", M.command,
        { desc = "Prepend buffer with a header, templated according to filepath and extension." }
    )
    M.autocmd()
end

return M
