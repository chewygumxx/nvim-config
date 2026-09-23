#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/neorg.d.lua
--
--

--
-- Local stand-in for nvim-neorg/neorg's own opts type, so
-- lua/spec/neorg.lua still resolves once the plugin is pruned from
-- ~/.local/share/nvim/lazy. Each entry of `load` is itself a
-- per-module class in neorg's real source (e.g. `core.dirman`); those
-- aren't individually vendored here, so `config` stays a loose table.
--

---@meta

---@class (exact) cgxx.spec.neorg.ModuleSpec
---@field config? table

---@class cgxx.spec.neorg.Config
---@field load? table<string, cgxx.spec.neorg.ModuleSpec>
