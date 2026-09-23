#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/comment.nvim.lua
--
--

--
-- Local stand-in for numToStr/Comment.nvim's own opts type, so
-- lua/spec/comment.nvim.lua still resolves once the plugin is pruned
-- from ~/.local/share/nvim/lazy. Transcribed from
-- Comment.nvim/lua/Comment/config.lua, whose full field set this
-- mirrors, so (exact) is safe here. Mappings/Toggler/Opleader/
-- ExtraMapping are upstream's own un-namespaced names; a same-named
-- class from another plugin would merge with these.
--

---@meta

---@class (exact) Mappings
---@field basic? boolean
---@field extra? boolean

---@class (exact) Toggler
---@field line?  string
---@field block? string

---@class (exact) Opleader
---@field line?  string
---@field block? string

---@class (exact) ExtraMapping
---@field below? string
---@field above? string
---@field eol?   string

---@class (exact) CommentConfig
---@field padding?   boolean | fun(): boolean
---@field sticky?    boolean
---@field ignore?    string | fun(): string
---@field mappings?  Mappings | false
---@field toggler?   Toggler
---@field opleader?  Opleader
---@field extra?     ExtraMapping
---@field pre_hook?  fun(ctx: table): string
---@field post_hook? fun(ctx: table)
