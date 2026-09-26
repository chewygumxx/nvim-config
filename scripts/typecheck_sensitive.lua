#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/scripts/typecheck_sensitive.lua
--
--

--
-- The repo-wide LuaLS check, one level more sensitive than the gate.
--
-- Usage: `nvim --headless -u scripts/minimal_init.lua
--         -l scripts/typecheck_sensitive.lua`
--
-- `.husky/pre-commit` and the "Typecheck" step of
-- `.github/workflows/lint-config.yaml` both run `--checklevel=Warning`,
-- which is what a commit has to pass. This runs the same check at
-- `Hint`, ie. everything those two deliberately ignore. It is a sweep to
-- read rather than a gate to satisfy: nothing runs it automatically, and
-- a Hint is not on its own a reason to change code that is already
-- right.
--
-- Run through Neovim rather than from a plain shell so that the child
-- process inherits `$VIMRUNTIME`, which `.luarc.json`'s
-- `workspace.library` needs to resolve `$VIMRUNTIME/lua`. The hook
-- exports it by hand for exactly this reason.
--

if vim.fn.executable("lua-language-server") == 0 then
    print("lua-language-server is not on PATH")
    os.exit(1)
end

local result = vim.system({
    "lua-language-server",
    "--check=" .. vim.fn.getcwd(),
    "--checklevel=Hint",
    "--check_format=pretty",
}, { text = true }):wait()

local output = (result.stdout or "") .. (result.stderr or "")
io.write(output)

-- The exit code is not trusted on its own: some releases report problems
-- and still exit 0, so the summary line is what is actually read
if output:find("no problems found", 1, true) then
    os.exit(0)
end
os.exit(result.code ~= 0 and result.code or 1)
