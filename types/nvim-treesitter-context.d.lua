#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/nvim-treesitter-context.d.lua
--
--

--
-- Local stand-in for nvim-treesitter/nvim-treesitter-context's own
-- opts type, so lua/spec/nvim-treesitter-context.lua still resolves
-- once the plugin is pruned from ~/.local/share/nvim/lazy. Transcribed
-- in full, `(exact)`, from
-- nvim-treesitter-context/lua/treesitter-context/config.lua.
--

---@meta

---@class (exact) TSContext.Config
---@field enable              boolean
---@field multiwindow         boolean
---@field max_lines           integer | string
---@field min_window_height   integer
---@field line_numbers        boolean
---@field multiline_threshold integer
---@field trim_scope          "outer" | "inner"
---@field zindex              integer
---@field mode                "cursor" | "topline"
---@field separator?          string
---@field on_attach?          fun(buf: integer): boolean

---@class (exact) TSContext.UserConfig: TSContext.Config
---@field enable?              boolean
---@field multiwindow?         boolean
---@field max_lines?           integer | string
---@field min_window_height?   integer
---@field line_numbers?        boolean
---@field multiline_threshold? integer
---@field trim_scope?          "outer" | "inner"
---@field zindex?              integer
---@field mode?                "cursor" | "topline"
---@field separator?           string
---@field on_attach?           fun(buf: integer): boolean
