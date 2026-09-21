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

    keys = {
        { "<leader>a", nil, desc = "AI/Claude Code" },
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

    ---@type PartialClaudeCodeConfig
    opts = {},
}

return M
