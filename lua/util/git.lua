#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:

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

--- Resolves the "owner/repo" slug of file's git remote.
---@param file?   string File to resolve from (default: current buffer)
---@param remote? string Remote name (default: "origin")
---@return string? slug "owner/repo", or nil if file has no such remote
M.slug = function(file, remote)
    file   = file or vim.fn.expand("%")
    remote = remote or "origin"

    local result = vim.system({
        "git",
        "-C",
        vim.fn.fnamemodify(file, ":p:h"),
        "remote",
        "get-url",
        remote,
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

---@class cgxx.git.gh.opts
---@field fmt cgxx.git.gh.opts.fmt

---@enum (key) cgxx.git.gh.opts.fmt
local gh_url_fmt = {
    ssh   = "git@github.com:%s.git",
    https = "https://github.com/%s.git",
}

--- Returns the repository GitHub URL of the provided slug
---@param slug string           owner/repo
---@param opts cgxx.git.gh.opts Additional options ie. fmt = "ssh"|"https"
---@return string url Repository GitHub URL
M.gh = function(slug, opts)
    local fmt = vim.tbl_get(opts, "fmt") or "ssh"

    if not gh_url_fmt[fmt] then
        return string.format("Bad format: %s", fmt)
    end

    return string.format(gh_url_fmt[fmt], slug)
end

return M
