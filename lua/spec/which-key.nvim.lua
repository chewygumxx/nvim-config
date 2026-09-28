#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/which-key.nvim.lua
--
--

--
-- Shows what a half-typed prefix can still become, from the mappings that
-- already exist: every entry comes from `vim.keymap.set`'s `desc`, so
-- nothing here restates a keymap and a binding cannot drift from its label.
-- https://github.com/folke/which-key.nvim
--
-- `M.opts.spec` names the prefixes rather than the keys, since a prefix is
-- the one thing no single mapping can describe. Where a prefix belongs to a
-- plugin, the label names the plugin, because that is what decides whether
-- the answer is here or in its documentation.
--
-- Only the options this config actually decides are set; everything else is
-- upstream's default, deliberately, so an upstream change in presentation
-- arrives rather than being frozen into a copy of its defaults.
--

---@module "lazy"
---@module "wk"

---@type LazyPluginSpec
local M = {
    "folke/which-key.nvim",
    event = "VeryLazy",
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "Buffer-local keymaps (which-key)",
        },
    },
}

---@type wk.Opts
M.opts = {
    preset = "classic",

    -- Instant for a plugin's own popup (which asked to be shown), and a
    -- beat's grace for a prefix the author may be part-way through typing.
    delay = function(ctx)
        return ctx.plugin and 0 or 200
    end,

    --
    -- The prefixes this config hands out, and who owns each.
    --
    -- `<leader>a` and `<leader>H` are two AI assistants that used to share
    -- `<leader>a`: `lua/spec/herdr-nvim.lua` records why it moved, and this
    -- popup is where that collision would otherwise have stayed invisible.
    --
    -- `<leader>h`, `<leader>i`, `<leader>l`, `<leader>n`, `<leader>r` and
    -- `<leader>t` are `lua/keymap/init.lua`'s, and `<leader>f`/`<leader>p`
    -- are absent on purpose: they belong to `lua/spec/mkdnflow.lua`, which
    -- carries `cond = false`, so labelling them would promise keys that do
    -- not exist.
    --
    spec = {
        { "<leader>a", group = "Claude Code" },
        { "<leader>H", group = "Herdr" },
        { "<leader>d", group = "Debug (DAP)" },
        { "<leader>h", group = "Search highlight, Harpoon" },
        { "<leader>i", group = "Inspect" },
        { "<leader>l", group = "Line numbers" },
        { "<leader>n", group = "Relative numbers" },
        { "<leader>r", group = "Reload, toggle" },
        { "<leader>t", group = "Text width" },
    },

    -- On: a mapping this config declares badly is a bug worth hearing
    -- about, and the warning names the mapping
    notify = true,

    -- Held back until a key is pressed in the two visual modes, where the
    -- popup would otherwise cover the selection being made
    defer = function(ctx)
        return ctx.mode == "V" or ctx.mode == "<C-V>"
    end,

    plugins = {
        marks     = true,
        registers = true,
        spelling  = { enabled = true, suggestions = 20 },
        presets   = {
            operators    = true,
            motions      = true,
            text_objects = true,
            windows      = true,
            nav          = true,
            z            = true,
            g            = true,
        },
    },

    -- The popup keeps clear of the cursor, so a prefix typed at the bottom
    -- of the window does not hide the line it is about to act on
    win = { no_overlap = true },

    -- `mod` last, so `<C-...>` and `<M-...>` sort after the plain keys a
    -- prefix is mostly made of
    sort = { "local", "order", "group", "alphanum", "mod" },
}

return M
