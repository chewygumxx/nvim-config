#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- luacheck: globals vim

-- 
-- 
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/util/git.lua
-- 
-- 

--
-- Helper functions for git
--

local M = {}

M.slug = function(file)
    local file = file or vim.fn.expand("%")

    local result = vim.system(
        { "git", "-C", vim.fn.fnamemodify(file, ":p:h"), "remote", "get-url", "origin" },
        { text = true }
    ):wait()
    if result.code ~= 0 or not result.stdout or result.stdout == "" then
        return
    end
    
    local slug = result.stdout:gsub("%s+$", ""):match("([%w_.%-]+/[%w_.%-]+)$") or ""
    return (slug:gsub("%.git$", ""))
end

M.path = function(file)
    local file = file or vim.fn.expand("%")

    local result = vim.system(
        { "git", "-C", vim.fn.fnamemodify(file, ":p:h"), "rev-parse", "--show-toplevel" },
        { text = true }
    ):wait()
    if result.code ~= 0 or not result.stdout or result.stdout == "" then
        return vim.fn.fnamemodify(file, ":~")
    end
    
    local root = result.stdout:gsub("%s+$", "")
    return ":" .. vim.fn.fnamemodify(file, ":p"):sub(#root + 1)
end

return M
