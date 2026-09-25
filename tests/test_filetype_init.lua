#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_filetype_init.lua
--
--

local eq = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

describe("filetype.setup", function()
    setup(function()
        require("filetype").setup()
    end)

    local match = function(filename)
        return (vim.filetype.match({ filename = filename }))
    end

    it("maps systemd/dosini extensions to dosini", function()
        eq(match("foo.service"), "dosini")
        eq(match("foo.socket"), "dosini")
        eq(match("foo.conf"), "dosini")
    end)

    it("maps this repo's ignore-file names to gitignore", function()
        eq(match("ignore"), "gitignore")
        eq(match(".chezmoiignore"), "gitignore")
        eq(match(".assetsignore"), "gitignore")
    end)

    it("maps *.conf under a gnupg/ directory to gpg", function()
        eq(match("/home/x/.gnupg/gpg.conf"), "gpg")
    end)

    it("maps *.conf under a hypr/ directory to hyprlang", function()
        eq(match("/home/x/.config/hypr/hyprland.conf"), "hyprlang")
    end)

    it(
        "maps files under a zsh config/func/functions directory to zsh",
        function()
            eq(match("/home/x/.config/zsh/foo"), "zsh")
            eq(match("/home/x/zsh/func/bar"), "zsh")
            eq(match("/home/x/zsh/functions/baz"), "zsh")
        end
    )

    it(
        "maps a note under a nex note/ directory to markdown.nex-note",
        function()
            eq(
                match("/home/x/dev/nex/note/2026-09-26-a-note.note.md"),
                "markdown.nex-note"
            )
        end
    )

    it("leaves plain markdown outside the nex repository alone", function()
        eq(match("/home/x/dev/nex/README.md"), "markdown")
        eq(match("/home/x/notes/a.note.md"), "markdown")
    end)

    it("routes every mapped filetype to a module that loads", function()
        for filetype, module in pairs(require("filetype").modmap) do
            -- Bound to a local first: `pcall` also returns the module
            -- itself, which would otherwise expand into this table
            local loads = pcall(require, "filetype." .. module)
            eq({ filetype, loads }, { filetype, true })
        end
    end)
end)
