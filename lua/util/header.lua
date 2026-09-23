#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/header.lua
--
--

--
-- Immutable header text for all text file formats
--

local M = {}

local util_modeline = require("util.modeline")
local util_shebang  = require("util.shebang")
local util_git      = require("util.git")

--- Strips trailing whitespace from every line, in place.
---@param lines string[]
---@return string[] lines Same table, mutated in place
local trim_lines = function(lines)
    for i = 1, #lines, 1 do
        lines[i] = lines[i]:gsub("[ \t]+$", "")
    end
    return lines
end

---@class util.HeaderInsertOpt
---@field commentstring? string Commentstring override

--- Prepends buf with a templated header (modeline, SPDX line, repo slug
--- and path), then Markdown frontmatter if buf's filetype is "markdown".
---@param file? string               Slug/path source (default: current buf)
---@param buf?  integer              Buffer to insert into (default: buf 0)
---@param opt?  util.HeaderInsertOpt
---@return nil
M.insert = function(file, buf, opt)
    if not (util_modeline and util_shebang and util_git) then
        return
    end

    file                = file or vim.fn.expand("%")
    buf                 = buf or 0
    opt                 = opt or {}
    local commentstring = opt.commentstring or vim.bo[buf].commentstring

    if commentstring == "" then
        return
    end

    -- Modeline
    ---@type string[]
    local lines = {}
    if vim.bo[buf].filetype == "markdown" then
        -- Markdown Frontmatter Start
        commentstring     = "# %s"
        lines[#lines + 1] = "---"
        lines[#lines + 1] = util_modeline.base({
            et = true,
            sw = 2,
            ft = "markdown",
            commentstring = commentstring,
        })
    else
        lines[#lines + 1] = util_shebang.get(file, buf)
        lines[#lines + 1] = util_modeline.base({
            et = true,
            sw = 4,
            ft = vim.bo[buf].filetype,
            commentstring = commentstring,
        })
    end

    -- (Slug and) Path
    ---@type string?
    local slug
    ---@type string?
    local upstream_slug
    local path = util_git.path(file)
    if path:find(":", 1, true) == 1 then
        slug          = util_git.slug(file)
        upstream_slug = util_git.slug(file, "upstream")
    end
    if path:find("~/.config", 1, true) == 1 then
        slug = "chewygumxx/dotfiles"
        path = path:gsub("~/%.config", ":/dot_config")
    end

    -- License
    local spdx        = upstream_slug and util_git.license(upstream_slug)
        or "GPL-3.0-only"
    lines[#lines + 1] = string.format(
        commentstring,
        "SPDX-License-Identifier: " .. spdx
    )

    if path then
        lines[#lines + 1] = ""
        lines[#lines + 1] = string.format(commentstring, "")
        lines[#lines + 1] = string.format(commentstring, "")
        if slug then
            if upstream_slug then
                lines[#lines + 1] = string.format(
                    commentstring,
                    "~" .. upstream_slug .. ".git"
                )
                lines[#lines + 1] = string.format(
                    commentstring,
                    "└─> ~" .. slug .. ".git"
                )
            else
                lines[#lines + 1] = string.format(
                    commentstring,
                    "~" .. slug .. ".git"
                )
            end
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

--- `XXInsertHeader` callback: inserts a header into the current buffer.
---@return nil
M.command = function()
    M.insert(vim.fn.expand("%"), vim.api.nvim_get_current_buf())
end

--- Registers the BufNewFile/FileType autocmd pair that defers header
--- insertion on a new file buffer until its filetype is known.
---@return nil
M.autocmd = function()
    vim.api.nvim_create_autocmd("BufNewFile", {
        group    = vim.api.nvim_create_augroup("cgxx.header_mark_pending", {
            clear = true,
        }),
        desc     = "Designates new file buffer for pending header insertion.",
        callback = function(opts)
            vim.b[opts.buf].cgxx_pending_header = true
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        group    = vim.api.nvim_create_augroup("cgxx.header_apply_insert", {
            clear = true,
        }),
        desc     = "Inserts templated header into new file buffer once filetype is known.",
        callback = function(opts)
            if vim.b[opts.buf].cgxx_pending_header then
                vim.b[opts.buf].cgxx_pending_header = nil
                M.insert(opts.file, opts.buf)
            end
        end,
    })
end

--- Registers the `XXInsertHeader` user command and its supporting autocmds.
---@return nil
M.setup = function()
    vim.api.nvim_create_user_command("XXInsertHeader", M.command, {
        desc = "Prepend buffer with a header, templated according to filepath and extension.",
    })
    M.autocmd()
end

return M
