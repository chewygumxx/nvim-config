#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_visual_traversal.lua
--
--

local visual_traversal = require("util.visual_traversal")
local eq               = MiniTest.expect.equality

describe("util.visual_traversal.command", function()
    it("resolves a callback for each known action", function()
        for _, act in ipairs({ "toggle", "enable", "disable" }) do
            eq(type(visual_traversal.command(act)), "function")
        end
    end)

    it("returns nil for an unknown action", function()
        eq(visual_traversal.command("bogus"), nil)
    end)
end)

describe("util.visual_traversal.enable/disable/toggle", function()
    local buf

    before_each(function() buf = vim.api.nvim_create_buf(false, true) end)
    after_each(function() vim.api.nvim_buf_delete(buf, { force = true }) end)

    it("enable sets the buffer-local flag", function()
        visual_traversal.enable(buf)
        eq(vim.b[buf].cgxx_visual_traversal, true)
    end)

    it("disable clears the buffer-local flag", function()
        visual_traversal.enable(buf)
        visual_traversal.disable(buf)
        eq(vim.b[buf].cgxx_visual_traversal, false)
    end)

    it("toggle flips the buffer-local flag", function()
        visual_traversal.disable(buf)
        visual_traversal.toggle(buf)
        eq(vim.b[buf].cgxx_visual_traversal, true)
        visual_traversal.toggle(buf)
        eq(vim.b[buf].cgxx_visual_traversal, false)
    end)

    it(
        "enable remaps j/k/0/$ to their g-prefixed motions, buffer-local",
        function()
            visual_traversal.enable(buf)
            -- `maparg()` only ever inspects buffer-local maps on the *current*
            -- buffer, so the query has to run with `buf` made current first.
            local map = vim.api.nvim_buf_call(
                buf,
                function() return vim.fn.maparg("j", "n", false, true) end
            )
            eq(map.buffer, 1)
            eq(map.rhs, "gj")
        end
    )

    it("disable restores the plain motions, buffer-local", function()
        visual_traversal.enable(buf)
        visual_traversal.disable(buf)
        local rhs = vim.api.nvim_buf_call(
            buf,
            function() return vim.fn.maparg("j", "n", false, true).rhs end
        )
        eq(rhs, "j")
    end)
end)
