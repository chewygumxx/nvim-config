#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/claudecode.nvim.lua
--
--

---@module "lazy"
---@module "claudecode"

---@type LazyPluginSpec
local M = {
    "coder/claudecode.nvim",
    lazy = true,
    dependencies = { "folke/snacks.nvim" },

    cmd = {
        "ClaudeCode",
        "ClaudeCodeFocus",
        "ClaudeCodeSelectModel",
        "ClaudeCodeAdd",
        "ClaudeCodeSend",
        "ClaudeCodeTreeAdd",
        "ClaudeCodeStatus",
        "ClaudeCodeStart",
        "ClaudeCodeStop",
        "ClaudeCodeOpen",
        "ClaudeCodeClose",
        "ClaudeCodeDiffAccept",
        "ClaudeCodeDiffDeny",
        "ClaudeCodeCloseAllDiffs",
    },

    -- No `{ "<leader>a", nil }` group placeholder: `lua/spec/which-key.nvim.lua`
    -- labels the prefix now, and an entry with no right-hand side is a
    -- lazy-load trigger on `<leader>a` itself, which is not wanted
    keys = {
        { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
        { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
        { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
        {
            "<leader>aC",
            "<cmd>ClaudeCode --continue<cr>",
            desc = "Continue Claude",
        },
        {
            "<leader>am",
            "<cmd>ClaudeCodeSelectModel<cr>",
            desc = "Select Claude model",
        },
        {
            "<leader>ab",
            "<cmd>ClaudeCodeAdd %<cr>",
            desc = "Add current buffer",
        },
        {
            "<leader>as",
            "<cmd>ClaudeCodeSend<cr>",
            mode = "v",
            desc = "Send to Claude",
        },
        {
            "<leader>as",
            "<cmd>ClaudeCodeTreeAdd<cr>",
            desc = "Add file",
            ft = {
                "NvimTree",
                "neo-tree",
                "oil",
                "minifiles",
                "netrw",
                "snacks_picker_list",
            },
        },
        -- Diff management
        { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
        { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },

    --
    -- Three decisions; everything else is upstream's default on purpose.
    --
    -- The provider is named rather than left as "auto" because `snacks.nvim`
    -- is a declared dependency above and loads eagerly, so the discovery
    -- "auto" performs can only ever reach the same answer, more slowly and
    -- less visibly.
    --
    -- `focus_after_send` departs from the default: a selection sent from a
    -- buffer is almost always followed by reading the reply, and with an
    -- in-Neovim provider the focus can actually move. The plugin warns at
    -- setup when a provider cannot honour this, which is the check that
    -- makes the two settings a pair rather than two independent lines.
    --
    ---@type PartialClaudeCodeConfig
    opts = {
        terminal         = { provider = "snacks" },
        focus_after_send = true,
        diff_opts        = { layout = "vertical" },
    },
}

return M
