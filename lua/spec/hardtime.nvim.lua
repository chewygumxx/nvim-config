#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/hardtime.nvim.lua
--
--

--
-- Counts repeated `h`/`j`/`k`/`l` and friends, and suggests the motion that
-- would have covered the same ground in one keystroke.
-- https://github.com/m4xshen/hardtime.nvim
--
-- Deliberately opinionated in `hint` mode rather than `block` on first
-- pass: a habit worth forming is worth being told about, but a config that
-- refuses a keystroke outright has to be right about the alternative every
-- time, and this one has not been lived with yet.
--

---@module "lazy"

---@type LazyPluginSpec
local M = {
    "m4xshen/hardtime.nvim",
    event = "VeryLazy",
}

---@type cgxx.spec.hardtime.Config
M.opts = {
    -- Say so rather than refuse; see the header
    restriction_mode = "hint",

    -- Left to the terminal. The keyboard habits are the point here, and
    -- unmapping every mouse event is a separate opinion this does not hold
    disable_mouse = false,

    --
    -- Arrow keys stay exactly as they were.
    --
    -- `false` and not `{}` or `{ "n" }`: the plugin's `setup` merges with
    -- `vim.tbl_deep_extend("force", ...)`, which recurses whenever both
    -- sides are tables, so a shorter list leaves the default's tail
    -- (`{ "n", "i" }`) in place. `false` replaces the value, and the
    -- handler loop's `if mode then` then maps nothing at all.
    --
    -- Insert mode is why this matters and not taste: `lua/spec/blink.cmp.lua`
    -- maps `<Up>`/`<Down>` to `select_prev`/`select_next`, so disabling them
    -- would take completion-menu navigation with it.
    --
    disabled_keys = {
        ["<Up>"]    = false,
        ["<Down>"]  = false,
        ["<Left>"]  = false,
        ["<Right>"] = false,
    },

    -- Buffers where `h`/`j`/`k`/`l` drive a list or a tree rather than
    -- traverse text, so a motion hint has nothing to suggest. Merged over
    -- the plugin's own defaults (`qf`, `netrw`, `lazy`, `mason`, the
    -- `dapui.*` and `neo%-tree.*` patterns, ...), which are kept.
    disabled_filetypes = {
        ["oil"]         = true,
        ["minifiles"]   = true,
        ["snacks_.*"]   = true,
        ["fzf"]         = true,
        ["harpoon"]     = true,
        ["checkhealth"] = true,
        ["dbee.*"]      = true,
    },
}

return M
