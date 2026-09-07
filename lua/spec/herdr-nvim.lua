#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/herdr-nvim.lua
--
--

---@module "vim"
---@module "lazy"
---@type LazySpec
local M = {
    "jtnovellis/herdr-nvim",
    enabled = false,

    -- The sidebar daemon needs it at startup for the reload watcher and the
    -- quit guard; everywhere else it can wait.
    lazy  = vim.env.HERDR_NVIM_DAEMON ~= "1",
    build = "sh scripts/build.sh",

    opts  = {},
}

M.cmd  = { "HerdrAsk", "HerdrReply", "HerdrAskTarget", "HerdrAnnotate",
    "HerdrAnnotations", "HerdrSend", "HerdrPaste", "HerdrPreview",
    "HerdrPickFile", "HerdrAgents" }

M.keys = { "<leader>ac", "<leader>ar", "<leader>aa", "<leader>al",
    "<leader>as", "<leader>aS", "<leader>af" }

return M
