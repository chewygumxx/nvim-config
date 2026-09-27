#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/scripts/gendoc.lua
--
--

--
-- Renders the LuaCATS annotations this repository already maintains into
-- the tracked `docs/` tree, using the `emmylua_doc_cli` that `mise.toml`
-- pins beside `luafmt`.
--
-- Usage: `nvim --headless -u scripts/minimal_init.lua
--         -l scripts/gendoc.lua`
--
-- Run through Neovim rather than from a plain shell so the child inherits
-- `$VIMRUNTIME`. `emmylua_doc_cli` discovers `.luarc.json` on its own and
-- that file's `workspace.library` names `$VIMRUNTIME/lua`, so from a bare
-- shell it would analyse against a library path that does not resolve and
-- say nothing about it. `scripts/typecheck_sensitive.lua` exists in this
-- form for the same reason.
--
-- `lua/spec/` is excluded rather than documented. 48 of this
-- repository's 103 Lua files are declarative `LazySpec` tables with no
-- callable API, so including them would fill the tree that the `Docs` job
-- in `.github/workflows/lint-config.yaml` has to diff without describing
-- anything a reader can call.
--
-- Two of the defaults are wrong for this use and are always passed:
-- `--output-format` is `html` unless asked otherwise, and `--output`
-- defaults to `./output`.
--
-- Written fail-closed for the reason `scripts/luals_untyped.lua` is,
-- against two failure modes peculiar to committing generated output:
--
--   * A run that produced nothing still exits 0, and an empty `docs/`
--     would then be committed as though it were the truth. So the new
--     tree is proved non-empty in a staging directory first, and `docs/`
--     is only replaced afterwards. That ordering also means a failed run
--     leaves the committed documentation intact rather than deleting it.
--
--   * A generator that only ever writes leaves the page for a deleted
--     module behind for good. `git diff` sees no change, so the gate
--     stays green over output that describes a module which no longer
--     exists. The tree is therefore replaced wholesale rather than
--     written over.
--
-- `emmylua_doc_cli` also emits an `mkdocs.yml` beside the Markdown, which
-- is deliberately left in the staging directory. It carries trailing
-- whitespace, and CI runs prettier over every `*.yml` that `git ls-files`
-- reports, so tracking it would leave two tools rewriting one file: the
-- standoff `.prettierignore` describes for `lazy-lock.json`. The Markdown
-- itself needs no such exclusion, having neither trailing whitespace nor
-- a missing final newline, and no gate globs `*.md`.
--

--- Prints msg and exits non-zero.
---
--- `print` rather than `io.stderr`, as in `scripts/luals_untyped.lua`:
--- selene's `lua51` standard library does not model `io.stderr`'s fields,
--- so writing there is a lint error.
---@param msg string
---@return nil
local function fatal(msg)
    print(msg)
    os.exit(1)
end

-- Asserted rather than searched for, as in `scripts/minitest.lua`: every
-- path below is relative to the invocation directory, and the wrong cwd
-- would otherwise present as a generator that found nothing to document
local anchor = ".luarc.json"
if vim.fn.filereadable(anchor) == 0 then
    fatal(
        string.format(
            "run from the repository root: no %s under %s",
            anchor,
            vim.fn.getcwd()
        )
    )
end

if vim.fn.executable("emmylua_doc_cli") == 0 then
    fatal("emmylua_doc_cli is not on PATH; mise.toml pins the version")
end

local staging   = vim.fn.tempname()
local generated = staging .. "/docs"
if vim.fn.mkdir(staging, "p") == 0 then
    fatal("could not create the staging directory " .. staging)
end

local excluded = table.concat({
    "lua/spec/**",
    "types/**",
    "tests/**",
    "scripts/**",
    "node_modules/**",
}, ",")

local result = vim.system({
    "emmylua_doc_cli",
    ".",
    "--output-format",
    "markdown",
    "--output",
    staging,
    "--site-name",
    "nvim-config",
    "--include",
    "lua/**/*.lua,lsp/*.lua,init.lua",
    "--exclude",
    excluded,
}, { text = true }):wait()

io.write((result.stdout or "") .. (result.stderr or ""))

if result.code ~= 0 then
    fatal("emmylua_doc_cli exited " .. tostring(result.code))
end

---@type string[]
local pages = {}
vim.list_extend(pages, vim.fn.globpath(generated, "**/*.md", false, true))

if #pages == 0 then
    fatal(
        "emmylua_doc_cli wrote no Markdown under " .. generated
            .. "; treating that as the generator not having run"
    )
end

-- A bare index satisfies the count above, so one page that has to exist
-- is named outright. `util.text` is the witness because every function in
-- it carries `---@param`/`---@return` and it is small enough to be an
-- unlikely deletion; a run that resolved no sources cannot produce it
local witness = generated .. "/modules/lua.util.text.md"
if vim.fn.filereadable(witness) == 0 then
    fatal("no page generated for util.text; expected " .. witness)
end

if vim.fn.isdirectory("docs") == 1 and vim.fn.delete("docs", "rf") ~= 0 then
    fatal("could not remove the existing docs/ tree")
end

for _, page in ipairs(pages) do
    local target = "docs/" .. page:sub(#generated + 2)
    local parent = vim.fs.dirname(target)
    if vim.fn.mkdir(parent, "p") == 0 then
        fatal("could not create " .. parent)
    end
    -- `readfile`/`writefile` rather than a copy through the shell: the
    -- generated pages all end in a newline, which round-trips exactly
    if vim.fn.writefile(vim.fn.readfile(page), target) ~= 0 then
        fatal("could not write " .. target)
    end
end

vim.fn.delete(staging, "rf")

io.write(string.format("docs/: %d page(s)\n", #pages))
