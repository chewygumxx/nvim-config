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
-- The list below is therefore both the expectation and the restore list,
-- so an undocumented mapping is also an unrestored one. That is not
-- theoretical: "gF" is set for `{ "n", "x" }` but was listed for "n"
-- alone, so the visual-mode override survived every later test file in
-- the suite. "registers nothing it does not document" is what stops that
-- recurring, by asserting the list is the whole set rather than a subset
-- of it.
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
        mode = "x",
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
    -- Registered by `keymap.gx` rather than `keymap` itself, and listed
    -- here anyway: `M.setup()` is what calls it, so it is one of the
    -- mappings this module is answerable for, and listing it is what makes
    -- `after_each` put "gx" back without a special case of its own
    {
        mode = "n",
        lhs  = "gx",
        desc = "Open URL or owner/repo under cursor",
    },
}

describe("keymap.setup", function()
    before_each(function()
        keymap.setup()
        -- `keymap.gx` defers its own mapping into `vim.schedule`, to read
        -- back whatever "gx" was bound to first. Waited for by *this*
        -- config's description rather than by any description at all:
        -- Neovim's own default "gx" carries one too, so the looser
        -- predicate is already true the moment `after_each` has deleted
        -- the override, and the wait then returns without ever pumping the
        -- pending callback. It would arrive later, inside whatever the
        -- next case waits on.
        local arrived = vim.wait(1000, function()
            return vim.fn.maparg("gx", "n", false, true).desc
                == require("keymap.gx").desc
        end, 5
        )
        assert(arrived, "keymap.gx never took over gx")
    end)

    after_each(function()
        for _, map in ipairs(mappings) do
            pcall(vim.keymap.del, map.mode, map.lhs)
        end
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

    --- Every "<mode> <lhs>" `keymap.setup()` asks `vim.keymap.set` for.
    ---
    --- Recorded from the calls rather than read back out of
    --- `nvim_get_keymap`, for two reasons. That answers in Neovim's own
    --- mode algebra, where one `{ "n", "x" }` mapping is listed under "x"
    --- and "v" and a "v" one under "v", "x" and "s", so a diff of it
    --- cannot be compared against the list above without reimplementing
    --- the expansion. And it cannot tell a mapping this config added from
    --- one of Neovim's that it overwrote: "gx" is mapped by default, so
    --- taking it over adds no entry at all.
    ---@return string[] requests Sorted, one per mode per call
    local requested = function()
        local real = vim.keymap.set
        ---@type string[]
        local seen = {}

        -- Written with the full parameter list, unused tail included,
        -- because a stub that takes fewer narrows LuaLS's idea of
        -- `vim.keymap.set` for the whole workspace: every real four
        -- argument call site then reports `redundant-parameter`
        ---@param mode  string | string[]
        ---@param lhs   string
        ---@param _rhs  string | function
        ---@param _opts vim.keymap.set.Opts?
        ---@return nil
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.keymap.set = function(mode, lhs, _rhs, _opts)
            ---@type string[]
            local modes = type(mode) == "table" and mode or { mode }
            for _, one in ipairs(modes) do
                table.insert(seen, one .. " " .. lhs)
            end
        end

        keymap.setup()
        -- `keymap.gx` defers into `vim.schedule`, so its call lands after
        -- `setup()` has returned and has to be waited for with the stub
        -- still installed
        local arrived = vim.wait(1000, function()
            return vim.tbl_contains(seen, "n gx")
        end, 5
        )

        vim.keymap.set = real
        assert(arrived, "keymap.gx never asked for its mapping")

        table.sort(seen)
        return seen
    end

    it("registers nothing it does not document", function()
        -- Set equality, not membership: the list above doubles as
        -- `after_each`'s restore list, so a mapping missing from it is one
        -- this file leaks into every test file that runs after it
        ---@type string[]
        local documented = {}
        for _, map in ipairs(mappings) do
            table.insert(documented, map.mode .. " " .. map.lhs)
        end
        table.sort(documented)

        eq(requested(), documented)
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
