#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/herdr-nvim.lua
--
--

---@module "vim"
---@module "lazy"

---@type LazyPluginSpec
local M = {
    "jtnovellis/herdr-nvim",

    -- The sidebar daemon needs it at startup for the reload watcher and the
    -- quit guard; everywhere else it can wait.
    lazy  = vim.env.HERDR_NVIM_DAEMON ~= "1",
    build = "sh scripts/build.sh",

    --
    -- Its own mappings are switched off and re-declared below under
    -- `<leader>H`, because `<leader>a` is `lua/spec/claudecode.nvim.lua`'s
    -- and the two collided on five keys (`ac`, `ar`, `aa`, `as`, `af`).
    --
    -- The collision had a winner but no announcement: `apply_keymaps`
    -- refuses to clobber a key another mapping already holds, and
    -- claudecode's arrive first as lazy.nvim's load stubs, so every one of
    -- those five was silently dropped and reported only by
    -- `:checkhealth herdr-nvim`. This plugin hardcodes its prefix with no
    -- option to move it, so `keymaps = false` plus the `keys` below is the
    -- only way to hold both sets at once.
    --
    -- The cost of switching them off wholesale: a mapping this plugin adds
    -- in a later release will not appear here until it is added below.
    -- `:checkhealth herdr-nvim` is where to notice that.
    --
    ---@type cgxx.spec.herdr.Config
    opts = { keymaps = false },
}

M.cmd = {
    "HerdrAsk",
    "HerdrReply",
    "HerdrAskTarget",
    "HerdrAnnotate",
    "HerdrAnnotations",
    "HerdrSend",
    "HerdrPaste",
    "HerdrPreview",
    "HerdrPickFile",
    "HerdrAgents",
}

--
-- The plugin's own set, letter for letter under `<leader>H` instead of
-- `<leader>a`, so muscle memory survives the move. Commands are used where
-- the plugin exposes one, and its module functions where it does not.
--
-- `:HerdrAsk<CR>` in visual mode takes no leading `<C-u>`: `:` from Visual
-- inserts the `'<,'>` range itself and the command reads it, so clearing
-- the command line would throw away the selection. The plugin's own table
-- says the same thing.
--
-- `]n`/`[n` and `]r`/`[r` are re-declared unchanged. They collide with
-- nothing, but `keymaps = false` withholds every mapping rather than only
-- the leader ones, so leaving them out would remove them.
--
M.keys = {
    {
        "<leader>Hc",
        "<cmd>HerdrAsk<cr>",
        desc = "Herdr: ask about this line",
    },
    {
        "<leader>Hc",
        ":HerdrAsk<CR>",
        mode = "x",
        desc = "Herdr: ask about this selection",
    },
    {
        "<leader>Hr",
        "<cmd>HerdrReply<cr>",
        desc = "Herdr: follow up with the last agent",
    },
    {
        "<leader>Ha",
        "<cmd>HerdrAnnotate<cr>",
        desc = "Herdr: queue a comment on this line",
    },
    {
        "<leader>Ha",
        ":HerdrAnnotate<CR>",
        mode = "x",
        desc = "Herdr: queue a comment on the selection",
    },
    {
        "<leader>Hl",
        "<cmd>HerdrAnnotations<cr>",
        desc = "Herdr: list annotations",
    },
    {
        "<leader>Hs",
        "<cmd>HerdrPaste<cr>",
        desc = "Herdr: paste annotations into the agent's input",
    },
    {
        "<leader>HS",
        "<cmd>HerdrSend<cr>",
        desc = "Herdr: send annotations to the agent",
    },
    {
        "<leader>Ht",
        "<cmd>HerdrAskTarget<cr>",
        desc = "Herdr: choose which agent to ask",
    },
    {
        "<leader>Hg",
        "<cmd>HerdrAgents<cr>",
        desc = "Herdr: list the agents visible from here",
    },
    {
        "<leader>Hf",
        "<cmd>HerdrPickFile<cr>",
        desc = "Herdr: pick a file the agent touched",
    },
    {
        "<leader>Hu",
        function()
            require("herdr-nvim").revert_hunk()
        end,
        desc = "Herdr: undo the agent's edit under the cursor",
    },
    {
        "<leader>Hk",
        function()
            require("herdr-nvim").keep_hunk()
        end,
        desc = "Herdr: keep the agent's edit under the cursor",
    },
    {
        "]n",
        function()
            require("herdr-nvim").next()
        end,
        desc = "Herdr: next annotation",
    },
    {
        "[n",
        function()
            require("herdr-nvim").prev()
        end,
        desc = "Herdr: previous annotation",
    },
    {
        "]r",
        function()
            require("herdr-nvim").next_hunk()
        end,
        desc = "Herdr: next agent edit",
    },
    {
        "[r",
        function()
            require("herdr-nvim").prev_hunk()
        end,
        desc = "Herdr: previous agent edit",
    },
}

return M
