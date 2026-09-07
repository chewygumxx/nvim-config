#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/orgmode.lua
--
--

--
-- I don't think I've ever used this
--

---@module "lazy"
---@type LazySpec
local M = {
    'nvim-orgmode/orgmode',

    ft = { 'org' },
    opts = {
        org_agenda_files = '~/nexus/orgmode/**/*',
        org_default_notes_file = '~/nexus/orgmode/refile.org',
    },
}

return M
