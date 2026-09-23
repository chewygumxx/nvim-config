#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/fidget.nvim.lua
--
--

--
-- Local stand-in for j-hui/fidget.nvim's own opts type, so
-- lua/spec/fidget.nvim.lua still resolves once the plugin is pruned
-- from ~/.local/share/nvim/lazy. `fidget.setup(opts)` takes an
-- untyped table upstream (no formal LuaCATS class), so this name is
-- invented locally rather than vendored; kept open since this repo
-- sets nothing today but the plugin has real, documented options.
--

---@meta

---@class cgxx.spec.fidget.Options
