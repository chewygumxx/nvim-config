#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/nvim-treesitter.d.lua
--
--

--
-- Local stand-in for nvim-treesitter/nvim-treesitter's own module and
-- InstallOptions types, so lua/spec/nvim-treesitter.lua still resolves
-- once the plugin is pruned from ~/.local/share/nvim/lazy. Transcribed
-- from nvim-treesitter/lua/nvim-treesitter/install.lua, covering only
-- the fields lua/spec/nvim-treesitter.lua actually touches.
--

---@meta

---@class InstallOptions
---@field force?    boolean
---@field generate? boolean
---@field max_jobs? integer
---@field summary?  boolean

---@class nvim-treesitter
---@field install fun(languages: string[] | string, options?: InstallOptions): boolean
