#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/nex.lua
--
--

--
-- Note scaffolding for the ~chewygumxx/nex.git repository. Backs the
-- dashboard's "New Note" entry and the `XXNexNote` user command: prompts
-- for a title, a description and a tag multi-select, then writes
-- `note/<ctime>-<slug>.note.md` and opens it with the cursor under its
-- heading.
--
-- The note is written to disk before it is edited, rather than opened as
-- a new-file buffer and populated in memory. `util.header`'s
-- BufNewFile/FileType pair would otherwise prepend its own Markdown
-- frontmatter to the buffer, which is exactly what this module is
-- generating in a note-specific shape.
--

local M = {}

local util_modeline = require("util.modeline")
local util_text     = require("util.text")

--- Repository the notes live in.
---@type string
M.root = vim.fn.expand("~/dev/nex")

--- Note subdirectory, relative to `M.root`.
---@type string
M.subdir = "note"

--- Repository slug, as written into a note's boxed header.
---@type string
M.slug = "chewygumxx/nex"

--- Compound filetype a note resolves to.
---@type string
M.filetype = "markdown.nex-note"

--- Suffix every note filename carries, `M.slugify`'d title excluded.
---@type string
M.extension = ".note.md"

--- Fold level a note opens at, per its modeline.
---@type integer
M.foldlevel = 3

--- Tag vocabulary offered by the multi-select. Authoritative: the picker
--- takes no free-text entry, so a tag that is not here cannot be chosen.
--- Edit this list to grow the vocabulary.
---@type string[]
M.tags = {
    "draft",
    "idea",
    "reference",
    "todo",
    "journal",
    "config",
    "nvim",
    "shell",
    "git",
    "lua",
    "web",
    "infra",
    "security",
    "reading",
}

--- Full-path pattern (for `vim.filetype.add`) matching a note.
--- `vim.filetype.add` implicitly anchors user-supplied patterns with
--- `^...$`, so this must NOT have a trailing `$` of its own.
---@type string
M.note_path_pattern = ".*/nex/note/[^/]*%.note%.md"

--- Reduces text to the lowercase, hyphen-separated form used in a note's
--- filename.
---@param text string
---@return string slug Empty if text holds no alphanumerics
M.slugify = function(text)
    local slug = text:lower()
    slug       = slug:gsub("[^%w]+", "-")
    slug       = slug:gsub("^%-+", "")
    slug       = slug:gsub("%-+$", "")
    return slug
end

--- Renders text as a YAML flow scalar, double-quoting it only when a
--- plain scalar would be ambiguous or invalid.
---@param text string
---@return string scalar
M.yaml_scalar = function(text)
    if text ~= "" and text:match("^[%w][%w _.()/-]*$") and not text:match(" $") then
        return text
    end
    local escaped = text:gsub("\\", "\\\\")
    escaped       = escaped:gsub('"', '\\"')
    return '"' .. escaped .. '"'
end

---@class (exact) cgxx.nex.Note
---@field title        string   Heading, `title:` key and filename source
---@field description? string   Body of the folded `description:` scalar
---@field tags?        string[] Selected tags, in `M.tags` order
---@field ctime?       string   YYYY-MM-DD (default: today)

--- Fills in note's defaults, in place.
---@param note cgxx.nex.Note
---@return cgxx.nex.Note note Same table, mutated in place
local defaulted = function(note)
    note.ctime       = note.ctime or tostring(os.date("%Y-%m-%d"))
    note.description = note.description or ""
    note.tags        = note.tags or {}
    return note
end

--- Builds note's filename, `M.root`/`M.subdir`-relative.
---@param note cgxx.nex.Note
---@return string filename
M.filename = function(note)
    note = defaulted(note)
    return note.ctime .. "-" .. M.slugify(note.title) .. M.extension
end

--- Builds note's absolute path.
---@param note cgxx.nex.Note
---@return string path
M.path = function(note)
    return M.root .. "/" .. M.subdir .. "/" .. M.filename(note)
end

--- Renders note as the full text of its file.
---@param note cgxx.nex.Note
---@return string[] lines
M.render = function(note)
    note = defaulted(note)

    -- Indented into the `__cgxx:` block scalar, so its comment syntax is
    -- Markdown frontmatter's ("# %s") rather than this buffer's own.
    local indent   = "  "
    local modeline = util_modeline.base({
        et            = true,
        sw            = 2,
        ft            = M.filetype,
        append        = " foldlevel=" .. tostring(M.foldlevel),
        commentstring = "# %s",
    })

    ---@type string[]
    local lines = {
        "---",
        "__cgxx: |",
        indent .. modeline,
        "",
        indent .. "#",
        indent .. "#",
        indent .. "# ~" .. M.slug .. ".git",
        indent .. "# ::: :/" .. M.subdir .. "/" .. M.filename(note),
        indent .. "#",
        indent .. "#",
        "",
        "ctime: " .. note.ctime,
        "title: " .. M.yaml_scalar(note.title),
    }

    -- A folded ">-" scalar cannot hold an empty body: YAML would read the
    -- next key as its content. Fall back to an empty flow scalar.
    if note.description == "" then
        lines[#lines + 1] = 'description: ""'
    else
        lines[#lines + 1] = "description: >-"
        for _, line in ipairs(
            util_text.wrap_comment(note.description, 80, {
                commentstring = indent .. "%s",
            })
        ) do
            lines[#lines + 1] = line
        end
    end

    if #note.tags == 0 then
        lines[#lines + 1] = "tags: []"
    else
        lines[#lines + 1] = "tags:"
        for _, tag in ipairs(note.tags) do
            lines[#lines + 1] = indent .. "- " .. M.yaml_scalar(tag)
        end
    end

    -- Two trailing blanks, not one: the cursor lands on the last of them,
    -- so the first thing typed is separated from the heading by a blank
    -- line rather than butting straight up against it.
    vim.list_extend(lines, {
        "---",
        "",
        "# " .. note.title,
        "",
        "",
    })

    return lines
end

--- Whether `M.root` exists and is the working tree of a git repository.
---@return boolean
M.is_worktree = function()
    if vim.fn.isdirectory(M.root) == 0 or vim.fn.executable("git") == 0 then
        return false
    end

    local result = vim.system({
        "git",
        "-C",
        M.root,
        "rev-parse",
        "--is-inside-work-tree",
    }, { text = true }):wait()
    if result.code ~= 0 or not result.stdout then
        return false
    end
    return vim.trim(result.stdout) == "true"
end

--- Prompts for a tag subset via `snacks.picker`'s multi-select (`<Tab>`
--- marks, `<CR>` confirms, falling back to the item under the cursor when
--- nothing is marked). Calls on_choice with nil if the picker is closed
--- without confirming, or if snacks is unavailable.
---@param on_choice fun(tags?: string[]) Receives tags in `M.tags` order
---@return nil
M.select_tags = function(on_choice)
    local ok, snacks = pcall(require, "snacks")
    if not ok then
        vim.notify(
            "snacks.nvim is unavailable: cannot select note tags",
            vim.log.levels.ERROR
        )
        on_choice(nil)
        return
    end

    ---@type snacks.picker.finder.Item[]
    local items = {}
    for idx, tag in ipairs(M.tags) do
        items[#items + 1] = { idx = idx, text = tag, tag = tag }
    end

    -- `on_close` fires on confirmation too, since confirming closes the
    -- picker; this latch keeps on_choice to exactly one call.
    local completed = false

    snacks.picker.pick({
        source = "nex_tags",
        title  = "Note Tags",
        items  = items,
        format = "text",
        layout = { preset = "select" },
        ---@param picker snacks.Picker
        ---@return nil
        confirm = function(picker)
            if completed then
                return
            end
            completed      = true
            local selected = picker:selected({ fallback = true })
            picker:close()

            -- Restore `M.tags` order, so a note's tag list does not
            -- depend on the order they happened to be marked in.
            table.sort(selected, function(a, b)
                return (a.idx or 0) < (b.idx or 0)
            end)
            ---@type string[]
            local tags = {}
            for _, item in ipairs(selected) do
                if item.tag then
                    tags[#tags + 1] = item.tag
                end
            end

            vim.schedule(function()
                on_choice(tags)
            end)
        end,
        ---@return nil
        on_close = function()
            if completed then
                return
            end
            completed = true
            vim.schedule(function()
                on_choice(nil)
            end)
        end,
    })
end

--- Writes note to disk and opens it, cursor on its trailing blank line.
--- Refuses to overwrite an existing note of the same name.
---@param note cgxx.nex.Note
---@return nil
M.create = function(note)
    local dir = M.root .. "/" .. M.subdir
    if vim.fn.isdirectory(dir) == 0 and vim.fn.mkdir(dir, "p") == 0 then
        vim.notify(
            "Could not create note directory: " .. dir,
            vim.log.levels.ERROR
        )
        return
    end

    local path = M.path(note)
    if vim.fn.filereadable(path) == 1 then
        vim.notify("Note already exists: " .. path, vim.log.levels.ERROR)
        return
    end

    local lines = M.render(note)
    if vim.fn.writefile(lines, path) ~= 0 then
        vim.notify("Could not write note: " .. path, vim.log.levels.ERROR)
        return
    end

    vim.cmd.edit(vim.fn.fnameescape(path))

    -- Synchronous, so that `lua/autocmd.lua`'s scheduled last-position
    -- restore sees a cursor that is no longer at (1, 0) and backs off.
    vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(0), 0 })
    vim.cmd.startinsert()
end

--- Prompts for a title, a description and a tag selection, then creates
--- the note. Aborts silently at any prompt that is cancelled, and on an
--- empty title (which has no filename to slugify).
---@return nil
M.new_note = function()
    if not M.is_worktree() then
        vim.notify(
            M.root .. " is not a git repository: create it before "
                .. "writing notes into it",
            vim.log.levels.ERROR
        )
        return
    end

    vim.ui.input({ prompt = "Note title: " }, function(title)
        if not title or vim.trim(title) == "" then
            return
        end
        title = vim.trim(title)

        if M.slugify(title) == "" then
            vim.notify(
                "Note title has no alphanumerics to slugify: " .. title,
                vim.log.levels.ERROR
            )
            return
        end

        vim.ui.input({ prompt = "Note description: " }, function(description)
            if description == nil then
                return
            end

            M.select_tags(function(tags)
                if not tags then
                    return
                end
                M.create({
                    title       = title,
                    description = vim.trim(description),
                    tags        = tags,
                })
            end)
        end)
    end)
end

--- `XXNexNote` callback.
---@return nil
M.command = function()
    M.new_note()
end

return M
