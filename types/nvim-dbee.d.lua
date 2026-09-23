#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/nvim-dbee.d.lua
--
--

--
-- Local stand-in for kndndrj/nvim-dbee's own opts type, so
-- lua/spec/nvim-dbee.lua still resolves once the plugin is pruned from
-- ~/.local/share/nvim/lazy. Upstream names this class plain `Config`;
-- if another installed plugin ever declares its own top-level `Config`
-- class, the two merge, so an unrelated field could show up on hover.
--

---@meta

---@class Config
