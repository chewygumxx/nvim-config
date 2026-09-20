-- vim: expandtab:shiftwidth=4:filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/.luacheckrc
--
--

std = "luajit"

globals = { "vim" }

-- `mini.test`'s `emulate_busted` temporarily injects these as globals while
-- collecting `tests/test_*.lua` (see `lua/spec/mini.nvim.lua`).
files["tests/"] = {
    globals = {
        "vim",
        "MiniTest",
        "describe",
        "it",
        "setup",
        "before_each",
        "after_each",
        "teardown",
    },
}
