#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_usercmd_redirect.lua
--
--

--
-- `usercmd.redirect_awkward_pager` exists because `:autocmd`, `:command`,
-- `:highlight` and `:map` all print more than a screenful and then hand it
-- to the pager. With a bang and no arguments they are redirected into a
-- scratch buffer instead; with either, they have to behave exactly as
-- they always did, since `:map <leader>x` and friends are typed far more
-- often than the bare listing.
--

local redirect = require("usercmd.redirect_awkward_pager")
local eq       = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

describe("usercmd.redirect_awkward_pager", function()
    before_each(function()
        vim.cmd("enew")
    end)

    after_each(function()
        local bufnr              = vim.api.nvim_get_current_buf()
        vim.bo[bufnr].modifiable = true
        vim.bo[bufnr].readonly   = false
        vim.cmd("enew!")
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
    end)

    --- Invokes the callback for vimcmd. Only the fields the callback
    --- reads are supplied, hence the cast.
    ---@param vimcmd string
    ---@param args   string
    ---@param bang   boolean
    ---@return nil
    local invoke = function(vimcmd, args, bang)
        ---@type vim.api.keyset.create_user_command.command_args
        ---@diagnostic disable-next-line: missing-fields
        local opts = { args = args, bang = bang }
        redirect.command(vimcmd)(opts)
    end

    it("redirects a bare bang into a scratch buffer", function()
        invoke("highlight", "", true)
        local bufnr = vim.api.nvim_get_current_buf()

        -- Scratch in every sense: no file behind it, wiped when hidden,
        -- and no swapfile for output nobody is editing
        eq(vim.bo[bufnr].buftype, "nofile")
        eq(vim.bo[bufnr].bufhidden, "wipe")
        eq(vim.bo[bufnr].swapfile, false)

        -- Read-only, and "q" closes it: this is output, not a document
        eq(vim.bo[bufnr].modifiable, false)
        eq(vim.bo[bufnr].readonly, true)
        eq(
            vim.fn.maparg("q", "n", false, true).desc,
            "Quit temp redirect buffer"
        )

        -- The point of the exercise: the listing itself, in a buffer,
        -- read from the top rather than from a pager
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        eq(#lines > 1, true)
        eq(table.concat(lines, "\n"):find("Normal", 1, true) ~= nil, true)
        eq(vim.api.nvim_win_get_cursor(0)[1], 1)
    end)

    -- The pass-through cases run the command for real, so they use
    -- `:echo ''` rather than `:highlight`: what is being asserted is the
    -- branch taken, and a real listing would land in the middle of this
    -- suite's own output, uncaptured.

    it("runs normally when given arguments", function()
        -- `:highlight Normal` with a bang still means "show me this one
        -- group", so redirecting it would swallow the answer
        invoke("echo", "''", true)
        eq(vim.bo[vim.api.nvim_get_current_buf()].buftype, "")
    end)

    it("runs normally without a bang", function()
        invoke("echo", "''", false)
        eq(vim.bo[vim.api.nvim_get_current_buf()].buftype, "")
    end)
end)
