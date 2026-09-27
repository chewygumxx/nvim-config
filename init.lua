#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/init.lua
--
--

--
-- Neovim initialisation root
--
-- Each module is required and set up directly, with no `require_guard` or
-- `setup_guard` wrapper. One existed and was removed deliberately: now that
-- this configuration is its own repository rather than a subdirectory of
-- the dotfiles repo, a misconfigured module is cheaply fixed by reverting
-- the checkout, so guarding every call against a broken sibling stopped
-- earning its complexity.
--

require("option").setup()
require("keymap").setup()

-- After option
--   and keymap      for overrides
require("filetype").setup()

-- After filetype,   for filetype registration
require("autocmd").setup()
require("usercmd").setup()

-- After  keymap,   for lazy-load keymap triggers involving vim.g.mapleader
-- After  filetype, for lazy-load filetype triggers
-- After  autocmd,  for augroup dependent plugin spec
--
-- The callee is `plugin`, not `util.lazy`: `lua/plugin.lua` decides the
-- spec list and hands it to `util.lazy.setup`, so the three notes above
-- name the dependency rather than what is called here.
require("plugin").setup()

-- After  util.lazy,  for treesitter parsing and colorscheme overwrite
require("highlight").setup()
