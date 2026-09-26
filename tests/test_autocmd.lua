#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_autocmd.lua
--
--

--
-- `autocmd.setup()` owns two autocmds of its own and delegates the rest
-- to the modules that implement them. Nothing else calls those
-- `M.autocmd()` functions, so a module dropped from the list here is a
-- feature that silently stops reacting to anything: no WIP snapshots, no
-- statusline invalidation, no headers on new files.
--

local eq = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

---@type cgxx.test.helpers
local helpers = dofile("tests/helpers.lua")
local eq_at   = helpers.labelled_equality

--- The augroup each delegated module registers into, named so that a
--- module dropped from `M.setup` fails here rather than in a session.
---
--- Also what `after_each` clears, so a module missing from this list keeps
--- reacting to events for every test file that runs after this one.
--- "creates no augroup it does not delegate to" holds the two to the same
--- set.
---@type table<string, string>
local delegated = {
    ["util.header (pending)"] = "cgxx.header_mark_pending",
    ["util.header (insert)"]  = "cgxx.header_apply_insert",
    ["filetype"]              = "cgxx.filetype",
    ["util.claude"]           = "cgxx.claude",
    ["util.wip"]              = "cgxx.wip",
    ["util.nex"]              = "cgxx.nex",
    ["util.markdown_table"]   = "cgxx.mdtable",
    ["util.statusline"]       = "cgxx.statusline",
}

describe("autocmd.setup", function()
    before_each(function()
        require("autocmd").setup()
    end)

    after_each(function()
        -- Cleared rather than deleted: `autocmd.lua` captures its
        -- augroup's id once, at module load, and deleting that group by
        -- name would leave the captured id dangling for the next
        -- `setup()`. Clearing keeps the id and empties the group, which
        -- is what stops these autocmds firing during later test files.
        vim.api.nvim_create_augroup("cgxx.file_entry", { clear = true })
        for _, group in pairs(delegated) do
            vim.api.nvim_create_augroup(group, { clear = true })
        end
    end)

    --- The autocmds registered in group.
    ---@param group string Augroup name
    ---@return vim.api.keyset.get_autocmds.ret[] autocmds
    local registered = function(group)
        return vim.api.nvim_get_autocmds({ group = group })
    end

    it("registers its own file-entry autocmds", function()
        ---@type table<string, boolean>
        local events = {}
        for _, autocmd in ipairs(registered("cgxx.file_entry")) do
            ---@type string
            local event   = autocmd.event
            events[event] = true
        end

        -- `BufEnter` as well as `BufReadPost`, since a scratch or
        -- `nofile` buffer is never the target of a file read
        eq(events.BufReadPost, true)
        eq(events.BufEnter, true)
    end)

    it("registers an autocmd for every module it delegates to", function()
        for module, group in pairs(delegated) do
            local ok, autocmds = pcall(registered, group)
            eq_at(
                module .. " registered into " .. group,
                ok and #autocmds > 0,
                true
            )
        end
    end)

    it("creates no augroup it does not delegate to", function()
        -- Watched at the call rather than read back out of
        -- `nvim_get_autocmds`, which cannot say who created a group that
        -- an earlier test file also asked for.
        --
        -- Only `M.setup()` is watched, not the module load: "cgxx
        -- .file_entry" is created once, when `autocmd.lua` is first
        -- required, so whether that write is observable here depends on
        -- which test file required the module first. The case above covers
        -- that group instead.
        local real = vim.api.nvim_create_augroup

        ---@type string[]
        local seen = {}

        -- Two parameters, matching the real arity: a narrower stub would
        -- retype the field for the whole workspace
        ---@param name  string
        ---@param _opts vim.api.keyset.create_augroup?
        ---@return integer id
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.api.nvim_create_augroup = function(name, _opts)
            table.insert(seen, name)
            -- Still created, since every `nvim_create_autocmd` call that
            -- follows needs a real group id to register into
            return real(name, { clear = true })
        end

        local ok, err               = pcall(require("autocmd").setup)
        vim.api.nvim_create_augroup = real
        assert(ok, err)

        ---@type string[]
        local expected = {}
        for _, group in pairs(delegated) do
            table.insert(expected, group)
        end

        table.sort(seen)
        table.sort(expected)
        eq(seen, expected)
    end)

    it("maps q to quit in an unmodifiable buffer", function()
        local bufnr              = vim.api.nvim_create_buf(false, true)
        vim.bo[bufnr].modifiable = false
        vim.api.nvim_exec_autocmds("BufEnter", { buffer = bufnr })

        ---@type vim.api.keyset.get_keymap[]
        local maps = vim.api.nvim_buf_get_keymap(bufnr, "n")
        local quit = nil
        for _, map in ipairs(maps) do
            if map.lhs == "q" then
                quit = map.rhs
            end
        end
        -- Neovim normalises the key notation it stores, so this is
        -- "<Cmd>" where the source says "<cmd>"
        eq(quit, "<Cmd>q<CR>")

        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("leaves a writable buffer's q alone", function()
        -- The mapping is buffer-local precisely so that it cannot escape
        -- into an ordinary editing buffer, where "q" starts a recording
        local bufnr              = vim.api.nvim_create_buf(false, true)
        vim.bo[bufnr].modifiable = true
        vim.bo[bufnr].readonly   = false
        vim.api.nvim_exec_autocmds("BufEnter", { buffer = bufnr })

        eq(#vim.api.nvim_buf_get_keymap(bufnr, "n"), 0)
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
end)
