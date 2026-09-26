#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_filetype_modules.lua
--
--

--
-- The specialised filetype modules, driven through the dispatcher that
-- actually reads them.
--
-- `tests/test_filetype_init.lua` covers detection (which path becomes which
-- filetype) and that every `M.modmap` entry names a module that loads.
-- `tests/test_filetype_nex_note.lua` covers one module by reading its
-- fields. Neither runs `M.config()`, so nothing asserted that a declared
-- option or highlight link is ever applied to a buffer: a module is "mostly
-- declarative" precisely because the dispatcher does the applying, and the
-- dispatcher was the untested half.
--
-- One case per mapped filetype rather than one loop over all of them, so a
-- module that breaks is named by the failure instead of stopping the loop
-- at whichever `pairs` order reached it first.
--
-- The fixture buffer is shown in a real split rather than passed by number.
-- `M.config` applies `local_opts` through `vim.opt_local`, which writes to
-- the current window for a window-scoped option ('spell', 'foldmethod'), so
-- a buffer that is merely current for the duration of an `nvim_buf_call`
-- would lose exactly those values again.
--

local filetype = require("filetype")
local eq       = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

--- The module a filetype is mapped to. `cgxx.filetype.Module` is declared
--- by `lua/filetype/init.lua`, which is why it is not restated here.
---@param ft string Filetype as `M.modmap` keys it
---@return cgxx.filetype.Module
local module_of = function(ft)
    ---@type cgxx.filetype.Module
    local module = require("filetype." .. filetype.modmap[ft])
    return module
end

--- Every filetype `M.modmap` routes somewhere, sorted so the generated
--- cases come out in a stable order rather than `pairs` order.
---@type string[]
local mapped = {}
for ft in pairs(filetype.modmap) do
    table.insert(mapped, ft)
end
table.sort(mapped)

--- A highlight attribute in the terms `nvim_get_hl` answers in.
---
--- Two conversions, both of them asymmetries of that API rather than of
--- these modules: a colour written as "#rrggbb" reads back as the integer
--- it denotes, and an attribute that is off is simply absent, so
--- `underline = false` (which `filetype.markdown` sets deliberately, to
--- undo an inherited underline) reads back as no `underline` at all.
---@param value any
---@return any comparable
local normalised = function(value)
    if type(value) == "string" and value:sub(1, 1) == "#" then
        return tonumber(value:sub(2), 16)
    end
    if value == false then
        return nil
    end
    return value
end

describe("filetype.config", function()
    ---@type integer
    local bufnr

    ---@type integer
    local winid

    ---@type table<string, vim.api.keyset.get_hl_info>
    local original

    ---@type fun(msg: string, level?: integer, opts?: table)
    local notify

    ---@type string[]
    local errors

    before_each(function()
        original = {}
        errors   = {}

        -- A split, so the buffer has a window of its own to carry
        -- window-scoped options
        vim.cmd("new")
        bufnr = vim.api.nvim_get_current_buf()
        winid = vim.api.nvim_get_current_win()

        -- Captured rather than silenced: `M.config` wraps each module's
        -- `setup` in a `pcall` and reports the failure through
        -- `vim.notify`, so a module that raises would otherwise dispatch
        -- "successfully" and say nothing a test could see
        notify = vim.notify
        ---@param msg   string
        ---@param level integer?
        ---@param opts  table?
        ---@return nil
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.notify = function(msg, level, opts)
            if level == vim.log.levels.ERROR then
                table.insert(errors, msg)
            else
                notify(msg, level, opts)
            end
        end
    end)

    after_each(function()
        vim.notify = notify
        for name, definition in pairs(original) do
            -- `nvim_get_hl` answers in the shape `nvim_set_hl` takes, but
            -- the two are declared as distinct types, so the round trip
            -- cannot be written without saying this
            ---@diagnostic disable-next-line: param-type-mismatch
            vim.api.nvim_set_hl(0, name, definition)
        end
        if vim.api.nvim_win_is_valid(winid) then
            vim.api.nvim_win_close(winid, true)
        end
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
    end)

    --- Dispatches ft against the fixture buffer, as the `FileType` autocmd
    --- in `M.autocmd()` does.
    ---@param ft string
    ---@return nil
    local dispatch = function(ft)
        vim.api.nvim_win_call(winid, function()
            ---@type vim.api.keyset.create_autocmd.callback_args
            ---@diagnostic disable-next-line: missing-fields
            local args = { match = ft, buf = bufnr }
            filetype.config(args)
        end)
    end

    --- opt's value in the fixture window and buffer, whichever it is
    --- scoped to.
    ---@param opt string
    ---@return any value
    local value_of = function(opt)
        ---@type any
        local value
        vim.api.nvim_win_call(winid, function()
            value = vim.api.nvim_get_option_value(opt, {})
        end)
        return value
    end

    for _, ft in ipairs(mapped) do
        it("dispatches " .. ft .. " without error", function()
            dispatch(ft)
            eq({ ft, errors }, { ft, {} })
        end)

        it("applies " .. ft .. "'s buffer-local options", function()
            -- `help` declares none: its options are set inside its own
            -- `setup`, and only for a real help window
            local want = module_of(ft).local_opts or {}
            dispatch(ft)

            ---@type string[]
            local wrong = {}
            for opt, expected in pairs(want) do
                local got = value_of(opt)
                if got ~= expected then
                    table.insert(
                        wrong,
                        string.format(
                            "%s is %s, want %s",
                            opt,
                            vim.inspect(got),
                            vim.inspect(expected)
                        )
                    )
                end
            end

            table.sort(wrong)
            eq({ ft, wrong }, { ft, {} })
        end)

        it("defines " .. ft .. "'s highlight groups", function()
            local module = module_of(ft)
            local want   = module.hlgroup_defs or {}

            -- A module defines its groups once per session and records
            -- that it has. Both are undone here so that the dispatch under
            -- test is the one doing the defining: otherwise whichever case
            -- reached this module first would leave every later assertion
            -- vacuously true.
            for name in pairs(want) do
                original[name] = vim.api.nvim_get_hl(0, { name = name })
                vim.api.nvim_set_hl(0, name, {})
            end
            module.highlights_defined = false

            dispatch(ft)

            ---@type string[]
            local wrong = {}
            for name, definition in pairs(want) do
                local got = vim.api.nvim_get_hl(0, { name = name })
                for _, attr in ipairs({ "link", "fg", "bold", "underline" }) do
                    if got[attr] ~= normalised(definition[attr]) then
                        table.insert(
                            wrong,
                            string.format(
                                "%s.%s is %s, want %s",
                                name,
                                attr,
                                vim.inspect(got[attr]),
                                vim.inspect(normalised(definition[attr]))
                            )
                        )
                    end
                end
            end

            table.sort(wrong)
            eq({ ft, wrong }, { ft, {} })
        end)
    end

    it("ignores a filetype it has no module for", function()
        -- The guard `M.config` opens with: an unmapped filetype must not
        -- reach `require("filetype.nil")`
        dispatch("zsh")
        eq(errors, {})
    end)
end)
