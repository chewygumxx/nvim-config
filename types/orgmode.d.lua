#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/types/orgmode.d.lua
--
--

--
-- Local stand-in for nvim-orgmode/orgmode's own opts type, so
-- lua/spec/orgmode.lua still resolves once the plugin is pruned from
-- ~/.local/share/nvim/lazy. Transcribed from
-- orgmode/lua/orgmode/config/_meta.lua's `OrgConfigOpts` (the real
-- `Org.setup(opts)` parameter type); only the two fields this repo
-- sets are declared out of its much larger real field set.
--

---@meta

---@class OrgConfigOpts
---@field org_agenda_files?       string | string[]
---@field org_default_notes_file? string
