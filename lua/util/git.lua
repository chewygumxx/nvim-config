#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/git.lua
--
--

--
-- Helper functions for git
--

local M = {}

--- Resolves the "owner/repo" slug of file's git remote "origin".
---@param file? string File to resolve from (default: current buffer)
---@return string? slug "owner/repo", or nil if file has no "origin" remote
M.slug = function(file)
    file = file or vim.fn.expand("%")

    local result = vim.system({
        "git",
        "-C",
        vim.fn.fnamemodify(file, ":p:h"),
        "remote",
        "get-url",
        "origin",
    }, { text = true }):wait()
    if result.code ~= 0 or not result.stdout or result.stdout == "" then
        return
    end

    local slug = result.stdout:gsub("%s+$", ""):match("([%w_.%-]+/[%w_.%-]+)$")
        or ""
    return (slug:gsub("%.git$", ""))
end

--- Resolves file's path relative to its git repository root.
---@param file? string File to resolve from (default: current buffer)
---@return string path ":"-prefixed root-relative path, or a "~"-relative
---  path if file isn't inside a git repository
M.path = function(file)
    file = file or vim.fn.expand("%")

    local result = vim.system({
        "git",
        "-C",
        vim.fn.fnamemodify(file, ":p:h"),
        "rev-parse",
        "--show-toplevel",
    }, { text = true }):wait()
    if result.code ~= 0 or not result.stdout or result.stdout == "" then
        return vim.fn.fnamemodify(file, ":~")
    end

    local root = result.stdout:gsub("%s+$", "")
    return ":" .. vim.fn.fnamemodify(file, ":p"):sub(#root + 1)
end

return M
