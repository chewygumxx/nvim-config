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
-- Headless test bootstrap: `nvim --headless -u scripts/minimal_init.lua
-- -l scripts/minitest.lua`.
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
-- only adding what test files actually need: this repo's own `lua/`, and
-- the already-installed `mini.nvim` for `mini.test`.
--

vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/mini.nvim")
