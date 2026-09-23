#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/store.nvim.lua
--
--

--
-- Local stand-in for alex-popov-tech/store.nvim's own opts type, so
-- lua/spec/store.nvim.lua still resolves once the plugin is pruned
-- from ~/.local/share/nvim/lazy. Upstream names this class plain
-- `UserConfig`; if another installed plugin ever declares its own
-- top-level `UserConfig` class, the two merge, so an unrelated field
-- could show up on hover. `layout`'s two values are validated at
-- runtime in store.nvim/lua/store/config.lua (`valid_layouts`).
--

---@meta

---@class UserConfig
---@field layout? "modal" | "tab"
