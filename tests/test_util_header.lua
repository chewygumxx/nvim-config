#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_util_header.lua
--
--

--
-- `util.header` writes the header convention every tracked file in this
-- repository carries, and a GitHub Action rewrites files with it on every
-- push. That makes it the one module here whose output lands in commits
-- nobody reviews by hand, so the exact lines are asserted rather than
-- pattern-matched.
--

local header = require("util.header")
local eq     = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

--- Runs git in dir, raising if it fails.
---@param dir string Repository to run in
---@param ... string git arguments
---@return nil
local git = function(dir, ...)
    local args = { ... }
    local cmd  = { "git", "-C", dir }
    vim.list_extend(cmd, args)

    local result = vim.system(cmd, { text = true }):wait()
    if result.code ~= 0 then
        error(
            string.format(
                "fixture `git %s` failed (%d): %s",
                table.concat(args, " "),
                result.code,
                result.stderr or ""
            )
        )
    end
end

describe("util.header.insert", function()
    ---@type string, string
    local dir, file

    ---@type integer[]
    local bufs

    before_each(function()
        dir = vim.fn.tempname()
        vim.fn.mkdir(dir .. "/sub", "p")
        git(dir, "init", "--quiet", "--initial-branch=hdr-test")
        git(
            dir,
            "remote",
            "add",
            "origin",
            "git@github.com:example-owner/example-repo.git"
        )

        file = dir .. "/sub/file.lua"
        vim.fn.writefile({ "local x = 1" }, file)
        bufs = {}
    end)

    after_each(function()
        for _, bufnr in ipairs(bufs) do
            if vim.api.nvim_buf_is_valid(bufnr) then
                vim.api.nvim_buf_delete(bufnr, { force = true })
            end
        end
        vim.fn.delete(dir, "rf")
    end)

    --- Loads path into a buffer of the given filetype, registered for
    --- teardown.
    ---@param path     string
    ---@param filetype string
    ---@return integer bufnr
    local opened = function(path, filetype)
        local bufnr = vim.fn.bufadd(path)
        vim.fn.bufload(bufnr)
        vim.bo[bufnr].filetype = filetype
        bufs[#bufs + 1]        = bufnr
        return bufnr
    end

    ---@param bufnr integer
    ---@return string[] lines
    local lines_of = function(bufnr)
        return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    end

    it("writes shebang, modeline, SPDX and the boxed repo path", function()
        local bufnr = opened(file, "lua")
        header.insert(file, bufnr)

        eq(lines_of(bufnr), {
            "#!/usr/bin/env lua",
            "-- vim:set expandtab shiftwidth=4 filetype=lua:",
            "-- SPDX-License-Identifier: GPL-3.0-only",
            "",
            "--",
            "--",
            "-- ~example-owner/example-repo.git",
            "-- ::: :/sub/file.lua",
            "--",
            "--",
            "",
            "local x = 1",
        })
    end)

    it("leaves no trailing whitespace on the blank comment lines", function()
        -- `.editorconfig` trims trailing whitespace and CI re-runs this
        -- generator, so a "-- " here would be rewritten on every push
        local bufnr = opened(file, "lua")
        header.insert(file, bufnr)

        for _, line in ipairs(lines_of(bufnr)) do
            eq({ line, line:find("%s$") }, { line, nil })
        end
    end)

    it("wraps a markdown header in frontmatter", function()
        local md = dir .. "/note.md"
        vim.fn.writefile({ "body" }, md)
        local bufnr = opened(md, "markdown")
        header.insert(md, bufnr)

        eq(lines_of(bufnr), {
            "---",
            "# vim:set expandtab shiftwidth=2 filetype=markdown:",
            "# SPDX-License-Identifier: GPL-3.0-only",
            "",
            "#",
            "#",
            "# ~example-owner/example-repo.git",
            "# ::: :/note.md",
            "#",
            "#",
            "",
            "ctime: " .. os.date("%Y-%m-%d"),
            "title: XXTITLE",
            "tags:  [  ]",
            "---",
            "",
            "# XXTITLE",
            "",
            "body",
        })
    end)

    it("falls back to a plain path outside any repository", function()
        local outside = vim.fn.tempname()
        vim.fn.mkdir(outside, "p")
        local loose = outside .. "/loose.lua"
        vim.fn.writefile({ "" }, loose)

        local bufnr = opened(loose, "lua")
        header.insert(loose, bufnr)

        -- No slug and no ":::" marker: both belong to a repository, and
        -- the path is whatever `util.git.path` falls back to
        local lines = lines_of(bufnr)
        eq(lines[7], "-- " .. vim.fn.fnamemodify(loose, ":~"))
        eq(lines[8], "--")
        vim.fn.delete(outside, "rf")
    end)

    it("names both repositories of a fork", function()
        git(
            dir,
            "remote",
            "add",
            "upstream",
            "git@github.com:upstream-owner/upstream-repo.git"
        )

        -- `util.git.license` shells out to `gh`, ie. the network and
        -- someone's credentials. Stubbed so this case asserts what the
        -- header does with an answer rather than how it gets one.
        local util_git = require("util.git")
        local real     = util_git.license
        ---@diagnostic disable-next-line: duplicate-set-field
        util_git.license = function()
            return "MIT"
        end

        local bufnr = opened(file, "lua")
        header.insert(file, bufnr)
        util_git.license = real

        local lines = lines_of(bufnr)
        eq(lines[3], "-- SPDX-License-Identifier: MIT")
        eq(lines[7], "-- ~upstream-owner/upstream-repo.git")
        eq(lines[8], "-- └─> ~example-owner/example-repo.git")
        eq(lines[9], "-- ::: :/sub/file.lua")
    end)

    it("honours a commentstring override", function()
        local bufnr = opened(file, "lua")
        header.insert(file, bufnr, { commentstring = "// %s" })

        eq(
            lines_of(bufnr)[2],
            "// vim:set expandtab shiftwidth=4 filetype=lua:"
        )
    end)

    it("inserts nothing without a commentstring", function()
        -- A filetype with no comment syntax has nowhere to put any of
        -- this, so the buffer must come back untouched
        local bufnr                 = opened(file, "")
        vim.bo[bufnr].commentstring = ""
        header.insert(file, bufnr)

        eq(lines_of(bufnr), { "local x = 1" })
    end)
end)

describe("util.header.setup", function()
    ---@type string
    local dir

    before_each(function()
        dir = vim.fn.tempname()
        vim.fn.mkdir(dir, "p")
        git(dir, "init", "--quiet", "--initial-branch=hdr-test")
        git(
            dir,
            "remote",
            "add",
            "origin",
            "git@github.com:example-owner/example-repo.git"
        )
        header.setup()
    end)

    after_each(function()
        vim.api.nvim_del_user_command("XXInsertHeader")
        -- Registered on a global augroup, so left in place they would
        -- prepend a header to every new buffer the rest of the suite opens
        vim.api.nvim_del_augroup_by_name("cgxx.header_mark_pending")
        vim.api.nvim_del_augroup_by_name("cgxx.header_apply_insert")
        vim.fn.delete(dir, "rf")
    end)

    it("registers the XXInsertHeader command", function()
        eq(vim.fn.exists(":XXInsertHeader"), 2)
    end)

    it("heads a new file buffer once its filetype is known", function()
        -- The reason this is two autocmds rather than one: at
        -- `BufNewFile` the filetype is not known yet, and the header is
        -- templated from it.
        --
        -- `BufNewFile` is raised explicitly rather than by `:edit`,
        -- because the real sequence depends on these autocmds being
        -- registered *before* Neovim's own filetype detection. That
        -- holds when `init.lua` registers them during startup, and is
        -- reversed here, where `header.setup()` necessarily runs long
        -- after startup: detection would then set the filetype, and run
        -- the `FileType` half, before the `BufNewFile` half had marked
        -- the buffer at all.
        local path  = dir .. "/fresh.lua"
        local bufnr = vim.fn.bufadd(path)
        vim.fn.bufload(bufnr)

        vim.api.nvim_exec_autocmds("BufNewFile", { buffer = bufnr })
        eq(vim.b[bufnr].cgxx_pending_header, true)

        -- A real assignment, so the `FileType` event carries the same
        -- buffer, file and match a detected filetype would
        vim.bo[bufnr].filetype = "lua"

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        eq(lines[1], "#!/usr/bin/env lua")
        eq(lines[7], "-- ~example-owner/example-repo.git")
        eq(lines[8], "-- ::: :/fresh.lua")

        -- Cleared, so a later `FileType` (a plugin re-detecting, say)
        -- cannot prepend a second header
        eq(vim.b[bufnr].cgxx_pending_header, nil)

        vim.bo[bufnr].filetype = "lua"
        eq(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), lines)

        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("leaves an existing file alone", function()
        -- `BufNewFile` is what marks a buffer for a header, and reading
        -- an existing file raises `BufRead` instead
        local path = dir .. "/existing.lua"
        vim.fn.writefile({ "return {}" }, path)

        vim.cmd.edit(vim.fn.fnameescape(path))
        local bufnr = vim.api.nvim_get_current_buf()

        eq(vim.b[bufnr].cgxx_pending_header, nil)
        eq(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), { "return {}" })
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
end)
