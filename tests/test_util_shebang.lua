#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_shebang.lua
--
--

local shebang = require("util.shebang")
local eq      = MiniTest.expect.equality

describe("util.shebang.get", function()
    it(
        "resolves a plain filetype shebang outside any source_dirs entry",
        function()
            eq(
                shebang.get("/tmp/foo.lua", 0, { ft = "lua" }),
                "#!/usr/bin/env lua"
            )
        end
    )

    it("returns nil for a filetype with no configured shebang", function()
        eq(shebang.get("/tmp/foo.txt", 0, { ft = "text" }), nil)
    end)

    it(
        "returns #!/bin/false for a file nested under a source_dirs entry",
        function()
            local home = vim.fn.expand("~")
            eq(
                shebang.get(home .. "/.config/nvim/lua/util/foo.lua", 0, {
                    ft = "lua",
                }),
                "#!/bin/false"
            )
        end
    )

    it(
        "returns #!/bin/false for a file directly inside a source_dirs entry",
        function()
            -- Regression: `path == dir` (no further nesting) used to fall
            -- through to the plain filetype shebang instead of matching.
            local home = vim.fn.expand("~")
            eq(
                shebang.get(home .. "/.config/nvim/lua/keymap.lua", 0, {
                    ft = "lua",
                }),
                "#!/bin/false"
            )
        end
    )
end)
