#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/.claude/skills/nvim-help/help.lua
--
--

--
-- Prints a `:help` entry headlessly, from Neovim's runtime and from every
-- plugin lazy.nvim has installed, at the versions actually on disk.
--
--   nvim --headless --clean -l .claude/skills/nvim-help/help.lua TAG [LINES]
--   nvim --headless --clean -l .claude/skills/nvim-help/help.lua --paths
--
-- `--clean` is what keeps this fast and side-effect free: no `init.lua`,
-- so no lazy.nvim bootstrap, no plugin loading and no LSP. The plugin
-- directories are put on 'runtimepath' by hand instead, which is all
-- `:help` needs, since lazy.nvim has already run `:helptags` on each.
-- lazy.nvim's `readme` root is added too: it holds the help pages built
-- from the READMEs of plugins that ship no vimdoc.
--
-- `--paths` prints the directories rather than an entry, for searching
-- by content with `grep` where no tag is known.
--
-- Everything is written with `io.write`, errors included, as in
-- `scripts/lazy_merge.lua`: selene's `lua51` standard library models
-- neither `io.stdout` nor `io.stderr`, and `print` under `-l` ends no
-- line. The exit code is what tells an error apart.
--

local data = vim.fn.stdpath("data")

---@type string[]
local plugins = vim.fn.glob(vim.fs.joinpath(data, "lazy", "*"), true, true)
for _, dir in ipairs(plugins) do
    vim.opt.rtp:append(dir)
end
vim.opt.rtp:append(vim.fs.joinpath(data, "readme"))

---@type string?
local tag = arg[1]
if tag == nil or tag == "" then
    io.write("usage: help.lua TAG [LINES] | help.lua --paths\n")
    os.exit(2)
end

if tag == "--paths" then
    ---@type string[]
    local docs = vim.api.nvim_get_runtime_file("doc", true)
    io.write(table.concat(docs, "\n"), "\n")
    os.exit(0)
end

local lines = tonumber(arg[2]) or 60

-- `:help` falls back to its best guess when there is no exact tag, so
-- the tag line it landed on is printed first and has to be read: it is
-- the only sign that the entry shown is not the one asked for.
local ok, err = pcall(vim.cmd.help, tag)
if not ok then
    io.write(tostring(err), "\n")
    os.exit(1)
end

local buf   = vim.api.nvim_get_current_buf()
local first = vim.fn.line(".")
local last  = first - 1 + lines
---@type string[]
local text = vim.api.nvim_buf_get_lines(buf, first - 1, last, false)

io.write(
    string.format("%s:%d\n", vim.api.nvim_buf_get_name(buf), first),
    table.concat(text, "\n"),
    "\n"
)
