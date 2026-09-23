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
end)
