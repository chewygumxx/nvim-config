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
require("plugin").setup()

-- After  util.lazy,  for treesitter parsing and colorscheme overwrite
require("highlight").setup()
