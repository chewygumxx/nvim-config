#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/scripts/minimal_init.lua
--
--

--
-- Headless test bootstrap:
-- nvim --headless -u scripts/minimal_init.lua -l scripts/minitest.lua
--
-- Deliberately does not source the real `init.lua`. `-u` only chooses
-- which file Neovim sources, it does not change `stdpath("config")`, so
-- a full bootstrap would still resolve `require("option")` and friends
-- against whatever `stdpath("config")` actually is on this machine
-- (typically the deployed config), not necessarily this checkout. Going
-- through `util.lazy.setup()` also isn't an option here: lazy.nvim's own
-- `performance.rtp.reset` clears runtimepath back to
-- `$VIMRUNTIME .. stdpath("config")` during setup, undoing any manual
-- `rtp` changes made beforehand. This script sidesteps both problems by
-- running against a runtimepath holding only what test files actually
-- need: this repo's own `lua/`, Neovim's runtime, and the
-- already-installed `mini.test`.
--
-- The machine's own configuration is *removed* rather than merely
-- outranked, because prepending this checkout is not enough to make the
-- suite hermetic: `stdpath("config")` would stay second, and for anyone
-- running the deployed copy of this very config that is a second, older
-- copy of every module under test. A module deleted or renamed in the
-- checkout would keep resolving from there, so the suite would pass
-- locally and fail in CI, where no such directory exists. The site
-- directories go for the same reason. What stays is `$VIMRUNTIME`, its
-- bundled packages and `/usr/lib/nvim`, which is where the Tree-sitter
-- parsers `tests/test_util_treesitter.lua` needs live.
--

--- Configuration roots whose runtimepath entries must not be inherited.
--- Concatenation, rather than a bare `stdpath` call, is what pins these
--- to `string`: `vim.fn.stdpath` is declared as returning a string for
--- some keys and a list for others.
---@type string[]
local ambient = {
    vim.fn.stdpath("config") .. "",
    vim.fn.stdpath("data") .. "/site",
}

---@type string[]
local config_dirs = vim.fn.stdpath("config_dirs")
vim.list_extend(ambient, config_dirs)

---@type string[]
local data_dirs = vim.fn.stdpath("data_dirs")
for _, dir in ipairs(data_dirs) do
    ambient[#ambient + 1] = dir .. "/site"
end

--- Whether path is one of the ambient roots, or lives under one.
---@param path string Runtimepath entry, with or without an "after" tail
---@return boolean inherited
local is_ambient = function(path)
    for _, root in ipairs(ambient) do
        -- Compared with a trailing separator on both sides so that this
        -- stays a path-component test: "~/.config/nvim" must not swallow
        -- a sibling "~/.config/nvim-config"
        if (path .. "/"):sub(1, #root + 1) == root .. "/" then
            return true
        end
    end
    return false
end

---@type string[]
local keep = {}
-- Read as a string for the same reason it is written as one below, and
-- because `vim.opt.rtp:get()` is declared as returning `any`
for _, path in ipairs(vim.split(vim.o.runtimepath, ",", { plain = true })) do
    if not is_ambient(path) then
        keep[#keep + 1] = path
    end
end

local minitest = vim.fn.stdpath("data") .. "/lazy/mini.test"
if vim.fn.isdirectory(minitest) == 0 then
    error("mini.test is not installed at: " .. minitest)
end

table.insert(keep, 1, vim.fn.getcwd())
keep[#keep + 1] = minitest

-- Written through `vim.o` rather than assigned to `vim.opt.rtp`:
-- assigning a list there narrows LuaLS's idea of that field to `string[]`
-- for the whole workspace, which then flags every `vim.opt.rtp:append()`
-- elsewhere in the repo as a call on an undefined field
vim.o.runtimepath = table.concat(keep, ",")
