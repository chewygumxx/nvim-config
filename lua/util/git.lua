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

--- Extracts the "owner/repo" slug from a remote URL, in either the SSH or
--- the HTTPS spelling.
---@param url string Remote URL, trailing whitespace permitted
---@return string? slug "owner/repo", or nil if url carries no such pair
local slug_of_url = function(url)
    local slug = url:gsub("%s+$", "")
        :match("([%w_.%-]+/[%w_.%-]+)$")
    if not slug then
        return
    end
    return (slug:gsub("%.git$", ""))
end

--- Resolves the "owner/repo" slug of file's git remote.
---@param file?   string File to resolve from (default: current buffer)
---@param remote? string Remote name (default: "origin")
---@return string? slug "owner/repo", or nil if file has no such remote
M.slug = function(file, remote)
    if vim.fn.executable("git") == 0 then
        return
    end
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

    return slug_of_url(result.stdout)
end

--- Resolves slug's SPDX license identifier via the GitHub API.
---@param slug string owner/repo
---@return string? spdx_id SPDX identifier, or nil on lookup failure
M.license = function(slug)
    if vim.fn.executable("gh") == 0 then
        return
    end

    local result = vim.system({
        "gh",
        "api",
        "repos/" .. slug .. "/license",
        "--jq",
        ".license.spdx_id",
    }, { text = true }):wait(5000)
    if result.code ~= 0 or not result.stdout or result.stdout == "" then
        return
    end

    local spdx_id = result.stdout:gsub("%s+$", "")
    if spdx_id == "null" then
        return
    end
    return spdx_id
end

--- Resolves file's path relative to its git repository root.
---@param file? string File to resolve from (default: current buffer)
---@return string path ":"-prefixed root-relative path, or a "~"-relative
---  path if file isn't inside a git repository
M.path = function(file)
    file = file or vim.fn.expand("%")
    if vim.fn.executable("git") == 0 then
        return vim.fn.fnamemodify(file, ":~")
    end

    local result = vim.system({
        "git",
        "-C",
        vim.fn.fnamemodify(file, ":p:h"),
        "rev-parse",
        "--show-prefix",
    }, { text = true }):wait()
    if result.code ~= 0 or not result.stdout then
        return vim.fn.fnamemodify(file, ":~")
    end

    -- `--show-prefix` (rather than slicing `:p` at `--show-toplevel`'s
    -- length) keeps this correct when file is reached through a symlinked
    -- path: git resolves both sides of that comparison itself, in the same
    -- invocation, instead of comparing a resolved toplevel against an
    -- unresolved `:p` path.
    local prefix = result.stdout:gsub("%s+$", "")
    return ":/" .. prefix .. vim.fn.fnamemodify(file, ":t")
end

--- Resolves the branch checked out by file's git repository.
---@param file? string File to resolve from (default: current buffer)
---@return string? branch Branch name, or nil if file's repository has a
---  detached HEAD, or file isn't inside a git repository
M.branch = function(file)
    if vim.fn.executable("git") == 0 then
        return
    end
    file = file or vim.fn.expand("%")

    -- `symbolic-ref` rather than `rev-parse --abbrev-ref HEAD`: the latter
    -- answers "HEAD" on a detached checkout, a valid-looking branch name
    -- the caller would then have to special-case. Failing outright leaves
    -- the "no branch" decision where it belongs.
    local result = vim.system({
        "git",
        "-C",
        vim.fn.fnamemodify(file, ":p:h"),
        "symbolic-ref",
        "--quiet",
        "--short",
        "HEAD",
    }, { text = true }):wait()
    if result.code ~= 0 or not result.stdout or result.stdout == "" then
        return
    end

    return (result.stdout:gsub("%s+$", ""))
end

---@class cgxx.git.info
---@field prefix string  Directory prefix relative to the repository root,
---  "" at the root itself
---@field branch string  Short branch name, "" on a detached HEAD
---@field slug   string? "owner/repo" of the "origin" remote, nil without one

--- Everything `M.path`, `M.branch` and `M.slug` answer separately, in one
--- process and without blocking.
---
--- The sync trio costs three spawns, which is fine once for a header or a
--- user command but not on a path that runs per buffer displayed: three
--- `:wait()` calls stall the UI for as long as git takes, multiplied by
--- every buffer in a sweep. One `sh -c` collapses that to a single
--- non-blocking spawn, the same trade `util.wip` makes for its snapshots.
---
--- Deliberately reports a detached HEAD as an empty branch rather than an
--- abbreviated SHA, leaving the substitution to the caller.
---@param file?    string                    Default: current buffer
---@param callback fun(info: cgxx.git.info?) Receives nil if file isn't
---  inside a git repository, or if git fails or times out. Always called
---  outside a fast event, so it may touch buffers and options.
---@return nil
M.info = function(file, callback)
    file = file or vim.fn.expand("%")

    local done = function(info)
        vim.schedule(function()
            callback(info)
        end)
    end

    if vim.fn.executable("git") == 0 or vim.fn.executable("sh") == 0 then
        done(nil)
        return
    end

    local dir = vim.fn.fnamemodify(file, ":p:h")

    -- `git -C` on a directory that doesn't exist yet (`:e new/dir/file`)
    -- is a guaranteed failure, so skip the spawn entirely
    if vim.fn.isdirectory(dir) == 0 then
        done(nil)
        return
    end

    -- `|| true` on the optional two: `set -e` would otherwise abort the
    -- script for the ordinary cases of a detached HEAD or no remote, and
    -- a failure there is information rather than an error. `--show-prefix`
    -- has no such guard on purpose -- when it fails, this is not a
    -- repository and the whole answer is nil.
    local info_sh = [[
set -eu

prefix=$(git rev-parse --show-prefix)
branch=$(git symbolic-ref --quiet --short HEAD || true)
url=$(git config --get remote.origin.url || true)

printf '%s\n%s\n%s\n' "$prefix" "$branch" "$url"
]]

    -- `vim.system` raises synchronously when the executable is missing,
    -- and a hung git on a network filesystem would otherwise never call
    -- back at all
    local ok = pcall(
        vim.system,
        { "sh", "-c", info_sh, "sh" },
        { cwd = dir, text = true, timeout = 2000 },
        function(result)
            if result.code ~= 0 or not result.stdout then
                done(nil)
                return
            end

            -- Exactly the three fields plus the trailing newline's empty
            -- tail. Anything else means a field contained a newline, ie. a
            -- pathological path, and is rejected rather than mis-parsed.
            local lines = vim.split(result.stdout, "\n", { plain = true })
            if #lines ~= 4 then
                done(nil)
                return
            end

            done({
                prefix = lines[1],
                branch = lines[2],
                slug   = lines[3] ~= "" and slug_of_url(lines[3]) or nil,
            })
        end
    )
    if not ok then
        done(nil)
    end
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
