#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/spell.lua
--
--

--
-- Keeps the personal word list's compiled `.add.spl` in step with the
-- `.add` it is built from.
--
-- `zg` and its siblings recompile on their own, but a word written into the
-- `.add` by hand, or arriving through `git pull`, is invisible until
-- `:mkspell` is run: Neovim loads only the `.spl`, and never compares the
-- two. That is the "words do not persist" symptom when the list is edited
-- as a file rather than through `zg`.
--

local M = {}

--- Every word list named in buf's 'spellfile', as absolute paths.
---@param buf? integer (default: current buffer)
---@return string[] paths
M.files = function(buf)
    ---@type string[]
    local paths   = {}
    local entries = vim.split(vim.bo[buf or 0].spellfile, ",", {
        plain     = true,
        trimempty = true,
    })
    for _, path in ipairs(entries) do
        paths[#paths + 1] = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
    end
    return paths
end

--- Whether path's compiled `.spl` is missing or older than path itself.
---@param path string The `.add` word list
---@return boolean stale
M.stale = function(path)
    local source = vim.uv.fs_stat(path)
    if source == nil then
        return false
    end
    local compiled = vim.uv.fs_stat(path .. ".spl")
    if compiled == nil then
        return true
    end
    if source.mtime.sec ~= compiled.mtime.sec then
        return source.mtime.sec > compiled.mtime.sec
    end
    return source.mtime.nsec > compiled.mtime.nsec
end

--- Recompiles each stale word list in buf's 'spellfile'.
---@param buf? integer (default: current buffer)
---@return string[] compiled The word lists that were recompiled
M.refresh = function(buf)
    ---@type string[]
    local compiled = {}
    for _, path in ipairs(M.files(buf)) do
        if M.stale(path) then
            vim.cmd.mkspell({
                args = { vim.fn.fnameescape(path) },
                bang = true,
                mods = { silent = true },
            })
            compiled[#compiled + 1] = path
        end
    end
    return compiled
end

--- Registers the autocmds that recompile a stale word list once at startup
--- and again whenever one is written from a buffer.
---@return nil
M.autocmd = function()
    local group = vim.api.nvim_create_augroup("cgxx.spell", { clear = true })

    vim.api.nvim_create_autocmd("VimEnter", {
        desc     = "Recompile a personal word list edited outside Neovim",
        group    = group,
        once     = true,
        callback = function()
            M.refresh()
        end,
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
        desc     = "Recompile a personal word list written by hand",
        group    = group,
        pattern  = "*.add",
        callback = function()
            M.refresh()
        end,
    })
end

return M
