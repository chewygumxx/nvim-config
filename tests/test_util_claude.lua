#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_claude.lua
--
--

--
-- `util.claude` folds away the quoted last response in a prompt buffer
-- Claude Code's external editor opens. Its inputs are a compound
-- filetype and a divider line, both of which come from software this
-- repository does not control, so each is pinned here rather than left
-- to be noticed the next time a prompt buffer opens wrong.
--

local claude = require("util.claude")
local eq     = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

describe("util.claude.is_prompt_buffer", function()
    ---@type integer
    local bufnr

    before_each(function()
        bufnr = vim.api.nvim_create_buf(false, true)
    end)
    after_each(function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("accepts the compound filetype lua/filetype resolves to", function()
        -- `markdown.claude` is what `lua/filetype/init.lua` maps the
        -- prompt file's path to, so the tail is what identifies it
        vim.bo[bufnr].filetype = "markdown.claude"
        eq(claude.is_prompt_buffer(bufnr), true)
    end)

    it("accepts the bare filetype", function()
        vim.bo[bufnr].filetype = "claude"
        eq(claude.is_prompt_buffer(bufnr), true)
    end)

    it("rejects an ordinary markdown buffer", function()
        vim.bo[bufnr].filetype = "markdown"
        eq(claude.is_prompt_buffer(bufnr), false)
    end)

    it("rejects a filetype that merely ends in claude", function()
        -- The tail test is on ".claude", not "claude", so a filetype
        -- like "notclaude" is not one of these buffers
        vim.bo[bufnr].filetype = "notclaude"
        eq(claude.is_prompt_buffer(bufnr), false)
    end)
end)

describe("util.claude.reply_divider_line", function()
    ---@type integer
    local bufnr

    before_each(function()
        bufnr = vim.api.nvim_create_buf(false, true)
    end)
    after_each(function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("finds the divider by substring, anywhere on the line", function()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "# quoted response",
            "# more",
            "# --- " .. claude.reply_divider .. " ---",
            "",
            "the reply",
        })
        eq(claude.reply_divider_line(bufnr), 3)
    end)

    it("reports nothing when the divider is absent", function()
        -- Which is the normal case: the quoted response only appears
        -- with "Show last response in external editor" enabled
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "just a prompt" })
        eq(claude.reply_divider_line(bufnr), nil)
    end)
end)

describe("util.claude.setup_fold_window", function()
    ---@type integer
    local bufnr

    before_each(function()
        vim.cmd("enew")
        bufnr = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "# quoted response",
            "# " .. claude.reply_divider,
            "",
            "the reply",
        })
    end)

    after_each(function()
        vim.cmd("enew!")
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("folds the quoted context closed, manually", function()
        vim.bo[bufnr].filetype = "markdown.claude"
        claude.setup_fold_window(bufnr)

        -- `foldmethod=manual` on purpose: this block is one leading "# "
        -- per line, which treesitter's own foldexpr reads as a run of
        -- headings
        eq(vim.wo.foldmethod, "manual")
        eq(vim.fn.foldclosed(1), 1)
        eq(vim.fn.foldclosedend(1), 2)

        -- The reply itself stays visible, which is the whole point
        eq(vim.fn.foldclosed(4), -1)
    end)

    it("leaves a buffer that is not a prompt alone", function()
        vim.bo[bufnr].filetype = "markdown"
        claude.setup_fold_window(bufnr)
        eq(vim.fn.foldclosed(1), -1)
    end)

    it("leaves a prompt without a divider alone", function()
        vim.bo[bufnr].filetype = "markdown.claude"
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "just a prompt" })
        claude.setup_fold_window(bufnr)
        eq(vim.fn.foldclosed(1), -1)
    end)

    it("refolds on every BufWinEnter, since folds are window-local", function()
        claude.autocmd()
        vim.bo[bufnr].filetype = "markdown.claude"

        -- A window that has never folded this buffer is exactly what
        -- a split produces, so the event has to be enough on its own
        vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = bufnr })
        eq(vim.fn.foldclosed(1), 1)

        vim.api.nvim_create_augroup("cgxx.claude", { clear = true })
    end)
end)
