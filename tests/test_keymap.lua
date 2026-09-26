#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_keymap.lua
--
--

--
-- `keymap.setup()` registers global mappings, several of them over
-- Neovim's own ("gf", "gF", "x", "p", ">", "<"), which is why each case
-- here puts them back afterwards: left in place they would change what
-- every later test file's `:normal!` does.
--
-- `vim.g.mapleader` is set when this module is first required rather than
-- in `M.setup()`, because lazy.nvim's lazy-loading keys are resolved
-- against it; `init.lua` requires `keymap` before `util.lazy` for exactly
-- that reason.
--

local keymap = require("keymap")
local eq     = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

--- Every mapping `keymap.setup()` registers: mode, left-hand side and
--- the description it carries.
---@type { mode: string, lhs: string, desc: string } []
local mappings = {
    {
        mode = "n",
        lhs  = "<leader>h",
        desc = ":noh - Clear highlight of search match",
    },
    { mode = "n", lhs = "<leader>rn", desc = "Toggle relativenumber" },
    { mode = "n", lhs = "<leader>nn", desc = "Blink relativenumber" },
    { mode = "n", lhs = "<leader>ln", desc = "Blink line number in gutter" },
    {
        mode = "n",
        lhs  = "<leader>tw",
        desc = "Format buffer line wrapping according to textwidth",
    },
    {
        mode = "n",
        lhs  = "<leader>in",
        desc = ":Inspect highlight groups under cursor",
    },
    { mode = "n", lhs = "<leader>rf", desc = "Reload foldmethod" },
    {
        mode = "x",
        lhs  = ">",
        desc = "Remain in visual mode after indenting",
    },
    {
        mode = "x",
        lhs  = "<",
        desc = "Remain in visual mode after indenting",
    },
    {
        mode = "n",
        lhs  = "gf",
        desc = "Open file and if provided, go to line number",
    },
    {
        mode = "x",
        lhs  = "gf",
        desc = "Open file and if provided, go to line number",
    },
    {
        mode = "n",
        lhs  = "gF",
        desc = "Create or open new file according to path under cursor",
    },
    {
        mode = "n",
        lhs  = "x",
        desc = "Blackhole Register: Single character deletion",
    },
    {
        mode = "v",
        lhs  = "p",
        desc = "Blackhole Register: Pasted over selection",
    },
}

describe("keymap.setup", function()
    before_each(function()
        keymap.setup()
        -- `keymap.gx` defers its own mapping into `vim.schedule`, to read
        -- back whatever "gx" was bound to first
        vim.wait(1000, function()
            return vim.fn.maparg("gx", "n", false, true).desc ~= nil
        end, 5
        )
    end)

    after_each(function()
        for _, map in ipairs(mappings) do
            pcall(vim.keymap.del, map.mode, map.lhs)
        end
        pcall(vim.keymap.del, "n", "gx")
    end)

    it("sets the leader before anything can be mapped against it", function()
        -- Not in `M.setup()`: plugin specs key their lazy-loading
        -- mappings off this, and they are read at require time
        eq(vim.g.mapleader, "\\")
    end)

    it("registers every mapping it documents", function()
        for _, map in ipairs(mappings) do
            local got = vim.fn.maparg(map.lhs, map.mode, false, true)
            eq({ map.mode, map.lhs, got.desc }, { map.mode, map.lhs, map.desc })
        end
    end)

    it("takes gx over, keeping the previous mapping as a fallback", function()
        eq(
            vim.fn.maparg("gx", "n", false, true).desc,
            require("keymap.gx").desc
        )
    end)

    it("does not make itself its own gx fallback", function()
        -- Running `setup` again is what a config reload does, and the
        -- description is the only handle on "this is already ours": read
        -- back naively, the second run would call the first through
        -- `M.fallback` forever
        local gx = require("keymap.gx")
        keymap.setup()
        vim.wait(1000, function()
            return false
        end, 50
        )

        local fallback = gx.fallback
        eq(fallback == nil or fallback.desc ~= gx.desc, true)
    end)
end)

describe("keymap.gx.url_at_cursor", function()
    ---@type integer
    local bufnr

    before_each(function()
        vim.cmd("enew")
        bufnr = vim.api.nvim_get_current_buf()
    end)

    after_each(function()
        vim.cmd("enew!")
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    --- Puts line in the buffer, moves the cursor to col, and resolves.
    ---@param line     string
    ---@param col      integer 1-based column to sit on
    ---@param filetype string
    ---@return string? url
    local at = function(line, col, filetype)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { line })
        vim.bo[bufnr].filetype = filetype
        vim.api.nvim_win_set_cursor(0, { 1, col - 1 })
        return require("keymap.gx").url_at_cursor()
    end

    it("resolves a quoted owner/repo in a Lua spec", function()
        local line = '    "chewygumxx/nvim-config",'
        eq(at(line, 10, "lua"), "https://github.com/chewygumxx/nvim-config")
    end)

    it("resolves a slug = \"owner/repo\" assignment anywhere", function()
        -- Unlike the bare quoted form, this one is not restricted to Lua
        local line = 'slug = "chewygumxx/nex"'
        eq(at(line, 12, "yaml"), "https://github.com/chewygumxx/nex")
    end)

    it("ignores a bare quoted slug outside Lua", function()
        -- Any quoted "a/b" is only a plugin spec in a Lua file; elsewhere
        -- it is as likely to be a path
        eq(at('"some/path"', 4, "yaml"), nil)
    end)

    it("only fires with the cursor inside the match", function()
        local line = 'x = "chewygumxx/nvim-config" -- trailing text'
        eq(at(line, 40, "lua"), nil)
    end)

    it("picks the match the cursor is in, not the first", function()
        -- The scan continues past each non-matching hit rather than
        -- stopping at the first one on the line
        local line = '{ "one/first", "two/second" }'
        eq(at(line, 20, "lua"), "https://github.com/two/second")
    end)

    it("resolves nothing on a line with no slug", function()
        eq(at("local x = 1", 5, "lua"), nil)
    end)
end)
