#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/header.lua
--
--

--
-- Immutable header text for all text file formats
--

local M = {}

local util_modeline = require("util.modeline")
local util_shebang  = require("util.shebang")
local util_git      = require("util.git")
local util_text     = require("util.text")

--- Indent carried by every line of a YAML block, the folded `description:`
--- and the `tags:` sequence alike. Two spaces because `.editorconfig` gives
--- Markdown the same.
---@type string
local block_indent = "  "

--- Width the folded `description:` scalar wraps at, indent included.
---@type integer
local description_width = 80

--- A `description:` longer than this is folded rather than left on one
--- line. 66 rather than 80 because the key and its separator take the
--- difference, so a value at this length still ends within 80 columns.
---@type integer
M.description_limit = 66

--- Fold level a generated Markdown file opens at, per its modeline. Three,
--- so a document folded on its headings shows down to `###`.
---@type integer
local markdown_foldlevel = 3

--- Stand-in written into both `title:` and the heading, for the author to
--- replace. Deliberately a `XX`-prefixed token, matching the user commands,
--- so it is greppable and cannot be mistaken for a real title.
---@type string
local title_placeholder = "XXTITLE"

--- Strips trailing whitespace from every line, in place.
---@param lines string[]
---@return string[] lines Same table, mutated in place
local trim_lines = function(lines)
    for i = 1, #lines, 1 do
        lines[i] = lines[i]:gsub("[ \t]+$", "")
    end
    return lines
end

--- Renders a `description:` key, folded when its value would not sit on
--- one line as plain YAML.
---
--- Folded (`>-`, so the value keeps no trailing newline) when the value is
--- longer than `M.description_limit` or is anything `util.text.yaml_scalar`
--- would have to quote, since a block scalar needs no quoting at all. An
--- empty value is a bare key, YAML's null, because a folded scalar with no
--- body would read the next key as its content.
---
--- Shared with `util.frontmatter`, which rewrites a hand-written value into
--- this same form on save.
---@param description string
---@return string[] lines
M.description = function(description)
    if description == "" then
        return { "description:" }
    end
    if #description <= M.description_limit
        and util_text.yaml_scalar(description) == description then
        return { "description: " .. description }
    end

    ---@type string[]
    local lines = { "description: >-" }
    vim.list_extend(
        lines,
        util_text.wrap_comment(description, description_width, {
            commentstring = block_indent .. "%s",
        })
    )
    return lines
end

---@class util.FrontmatterOpt
---@field title        string   Heading, and the `title:` key
---@field slug?        string   Repository, boxed as `~slug.git`
---@field fork_slug?   string   Fork of slug, boxed beneath it
---@field path?        string   Repo-relative path, boxed after `::: `
---@field spdx?        string   SPDX identifier; the key is omitted without one
---@field filetype?    string   Modeline `filetype` (default: "markdown")
---@field shiftwidth?  integer  Modeline `shiftwidth` (default: 2)
---@field foldlevel?   integer  Modeline `foldlevel`; omitted without one
---@field description? string   Value of `description:`, folded if long
---@field tags?        string[] `tags:` block sequence, in the order given
---@field ctime?       string   YYYY-MM-DD (default: today)
---@field mtime?       string   YYYY-MM-DD (default: ctime)

--- A Markdown document's header, in the two places it lives.
---@class util.Frontmatter
---@field head string[] The frontmatter and the boxed repository notation
---@field tail string[] The modeline, which closes the document

--- The lines of the HTML comment box naming a file's repository and path,
--- `<!--` to `-->` inclusive.
---
--- Every line inside opens `   - `, aligning the dashes under the `!` of
--- `<!--`, the way a C block comment aligns its `*`s.
---@param slug?      string
---@param fork_slug? string
---@param path?      string
---@return string[] lines
M.box = function(slug, fork_slug, path)
    local prefix = "   - "
    ---@type string[]
    local lines = { "<!--", "   -" }

    if slug then
        lines[#lines + 1] = prefix .. "~" .. slug .. ".git"
        if fork_slug then
            lines[#lines + 1] = prefix .. "└─> ~" .. fork_slug .. ".git"
        end
    end
    if path then
        lines[#lines + 1] = prefix .. (slug and "::: " .. path or path)
    end

    vim.list_extend(lines, { "   -", "   -->" })
    return lines
end

--- Renders a Markdown file's header: YAML frontmatter and the boxed
--- repository notation at its head, and the modeline at its foot.
---
--- The frontmatter is plain data, so a YAML parser sees nothing it does
--- not need. The repository box is an HTML comment, which no renderer
--- shows. The modeline goes last, since Vim reads one from the final
--- 'modelines' lines as readily as from the first and frontmatter must
--- open on line 1.
---
--- Shared with `util.nex`, which renders the same shape for a note: this is
--- the one description of the format, so a change here reaches both.
---@param opt util.FrontmatterOpt
---@return util.Frontmatter frontmatter
M.frontmatter = function(opt)
    local ctime = opt.ctime or tostring(os.date("%Y-%m-%d"))
    local tags  = opt.tags or {}

    ---@type string[]
    local head = {
        "---",
        "ctime: " .. ctime,
        "mtime: " .. (opt.mtime or ctime),
    }
    if opt.spdx then
        head[#head + 1] = "spdx: " .. opt.spdx
    end
    head[#head + 1] = "title: " .. util_text.yaml_scalar(opt.title)
    vim.list_extend(head, M.description(opt.description or ""))

    head[#head + 1] = "tags:"
    for _, tag in ipairs(tags) do
        head[#head + 1] = block_indent .. "- " .. util_text.yaml_scalar(tag)
    end
    head[#head + 1] = "---"
    head[#head + 1] = ""
    vim.list_extend(head, M.box(opt.slug, opt.fork_slug, opt.path))

    local modeline = util_modeline.base({
        et            = true,
        sw            = opt.shiftwidth or 2,
        ft            = opt.filetype or "markdown",
        append        = opt.foldlevel
            and " foldlevel=" .. tostring(opt.foldlevel)
            or nil,
        commentstring = "<!-- %s -->",
    })

    return { head = trim_lines(head), tail = { modeline } }
end

--- The plain-comment box naming a file's repository and path, padded by
--- two empty comment lines either side, each wrapped in commentstring.
---
--- The plain counterpart of `M.box`. Split out of `M.plain` because
--- `M.apply` re-renders the box alone on every save, to follow a file that
--- has been renamed or moved.
---@param commentstring string
---@param slug?         string
---@param fork_slug?    string
---@param path          string
---@return string[] lines
M.plain_box = function(commentstring, slug, fork_slug, path)
    local empty = string.format(commentstring, "")
    ---@type string[]
    local lines = { empty, empty }

    if slug then
        lines[#lines + 1] = string.format(commentstring, "~" .. slug .. ".git")
        if fork_slug then
            lines[#lines + 1] = string.format(
                commentstring,
                "└─> ~" .. fork_slug .. ".git"
            )
        end
        lines[#lines + 1] = string.format(commentstring, "::: " .. path)
    else
        lines[#lines + 1] = string.format(commentstring, path)
    end

    vim.list_extend(lines, { empty, empty })
    return trim_lines(lines)
end

--- How far down a file `M.find_box` looks for the first line of a box.
--- `M.plain` opens one on line 5 at the latest, beneath a shebang, the
--- modeline, the SPDX line and a blank; the rest is slack for a line added
--- by hand, and too little to reach a lookalike in a file's body.
---@type integer
local box_limit = 8

--- The 1-indexed first and last lines of the box `M.plain_box` renders, if
--- lines carry one near their head.
---
--- Recognised by shape rather than content: two empty comment lines, one
--- to three that name a repository or path, ie. open on `~` or `:`, and two
--- more empty ones. A padded comment of prose has the same frame and is
--- left alone, since rewriting it would replace the prose with a path.
---@param lines         string[]
---@param commentstring string
---@return integer? first
---@return integer? last
M.find_box = function(lines, commentstring)
    local empty          = vim.trim(string.format(commentstring, ""))
    local prefix, suffix = commentstring:match("^(.-)%%s(.-)$")
    if prefix == nil then
        return nil
    end

    --- The text a comment line wraps, or nil if line is not one.
    ---@param line string
    ---@return string? text
    local comment_text = function(line)
        if not vim.startswith(line, prefix) or not vim.endswith(line, suffix)
            or #line < #prefix + #suffix then
            return nil
        end
        return vim.trim(line:sub(#prefix + 1, #line - #suffix))
    end

    for first = 1, math.min(#lines, box_limit) do
        if lines[first] == empty and lines[first + 1] == empty then
            local text = comment_text(lines[first + 2] or "")
            if text and text:match("^[~:]") then
                -- A slug, a fork and a path at most
                local last = first + 2
                while last < first + 5 and lines[last] ~= empty
                    and comment_text(lines[last] or "") do
                    last = last + 1
                end
                if lines[last] == empty and lines[last + 1] == empty then
                    return first, last + 1
                end
            end
        end
    end
    return nil
end

---@class util.PlainHeaderOpt
---@field commentstring string           printf-style wrapper
---@field slug?         string           Repository, boxed as `~slug.git`
---@field fork_slug?    string           Fork of slug, boxed beneath it
---@field path?         string           Repo-relative path, boxed after `::: `
---@field spdx?         string           SPDX identifier; the line is omitted without one
---@field shebang?      string           Interpreter line, above the modeline
---@field modeline?     util.ModelineOpt Overrides; `commentstring` is forced

--- Renders the plain-comment form of this repository's file header: an
--- optional shebang, the modeline, the SPDX line and the boxed repository
--- notation, each wrapped in opt.commentstring.
---
--- Split out of `M.insert` rather than left inline there because
--- `util.vimdoc` renders the same box into generated help, where there is
--- no buffer to take a 'commentstring' or a filetype from. This is now the
--- one description of the plain shape, as `M.frontmatter` is of the
--- Markdown one.
---@param opt util.PlainHeaderOpt
---@return string[] lines
M.plain = function(opt)
    local commentstring = opt.commentstring
    ---@type util.ModelineOpt
    local modeline_opt = vim.tbl_extend(
        "force",
        { et = true, sw = 4 },
        opt.modeline or {},
        { commentstring = commentstring }
    )

    ---@type string[]
    local lines = {}
    -- Assigning nil is a no-op rather than a hole, which is why an absent
    -- shebang needs no branch
    lines[#lines + 1] = opt.shebang
    lines[#lines + 1] = util_modeline.base(modeline_opt)

    if opt.spdx then
        local identifier  = "SPDX-License-Identifier: " .. opt.spdx
        lines[#lines + 1] = string.format(commentstring, identifier)
    end

    if opt.path then
        lines[#lines + 1] = ""
        vim.list_extend(
            lines,
            M.plain_box(commentstring, opt.slug, opt.fork_slug, opt.path)
        )
    end

    lines[#lines + 1] = ""

    return trim_lines(lines)
end

---@class util.HeaderLocation
---@field path       string Repo-relative (`:/a.md`), or `~`-relative outside one
---@field slug?      string The repository, upstream first when a fork
---@field fork_slug? string The fork, when the file belongs to one
---@field upstream?  string The upstream's slug, which decides the licence

--- Where file lives, as the header box names it.
---
--- A fork is boxed upstream first and the fork beneath it, so when an
--- `upstream` remote exists its slug is what `slug` holds and the file's
--- own repository moves to `fork_slug`. Anything under `~/.config` is the
--- dotfiles repository's, at the path chezmoi gives it there.
---
--- Split out of `M.insert` because `util.frontmatter` re-derives the same
--- box on every save, to follow a file that has been renamed or moved.
---@param file string
---@return util.HeaderLocation location
M.locate = function(file)
    ---@type string?
    local slug
    ---@type string?
    local upstream
    local path = util_git.path(file)
    if path:find(":", 1, true) == 1 then
        slug     = util_git.slug(file)
        upstream = util_git.slug(file, "upstream")
    end
    if path:find("~/.config", 1, true) == 1 then
        slug = "chewygumxx/dotfiles"
        path = path:gsub("~/%.config", ":/dot_config")
    end

    return {
        path      = path,
        slug      = upstream or slug,
        fork_slug = upstream and slug or nil,
        upstream  = upstream,
    }
end

---@class util.HeaderInsertOpt
---@field commentstring? string Commentstring override

--- Inserts a templated header into buf: the plain-comment form (modeline,
--- SPDX line, repository box) at its head, or for a "markdown" buffer the
--- frontmatter and box at its head and the modeline at its foot.
---@param file? string               Slug/path source (default: current buf)
---@param buf?  integer              Buffer to insert into (default: buf 0)
---@param opt?  util.HeaderInsertOpt
---@return nil
M.insert = function(file, buf, opt)
    file                = file or vim.fn.expand("%")
    buf                 = buf or 0
    opt                 = opt or {}
    local commentstring = opt.commentstring or vim.bo[buf].commentstring

    if commentstring == "" then
        return
    end

    local location = M.locate(file)

    -- License. This repository's own unless the file belongs to a fork, in
    -- which case the upstream's; a lookup that fails says so rather than
    -- falling back to ours. `NOASSERTION` is SPDX's own word for "not
    -- determined", so the header stays valid and the gap stays visible.
    local spdx = "GPL-3.0-only"
    if location.upstream then
        local upstream_spdx = util_git.license(location.upstream)
        if not upstream_spdx then
            vim.notify(
                "Header: no licence found for " .. location.upstream
                    .. "; wrote NOASSERTION",
                vim.log.levels.WARN
            )
        end
        spdx = upstream_spdx or "NOASSERTION"
    end

    --
    -- Markdown is a different document, not a differently commented one:
    -- the SPDX identifier becomes a frontmatter key, the box an HTML
    -- comment beneath it and the modeline moves to the foot, so
    -- `M.frontmatter` renders the whole thing rather than this function
    -- interleaving it with the plain-comment case.
    --
    -- Compound filetypes are deliberately excluded by the equality check:
    -- a `markdown.nex-note` buffer is `util.nex`'s to render, and a
    -- `markdown.agentprompt` one carries no repository frontmatter at all.
    --
    if vim.bo[buf].filetype == "markdown" then
        local header = M.frontmatter({
            slug      = location.slug,
            fork_slug = location.fork_slug,
            path      = location.path,
            spdx      = spdx,
            foldlevel = markdown_foldlevel,
            title     = title_placeholder,
        })
        local head   = vim.list_extend(header.head, {
            "",
            "# " .. title_placeholder,
            "",
        })
        vim.api.nvim_buf_set_lines(buf, 0, 0, false, head)

        -- One blank line between the body and the modeline, without
        -- doubling one the body already ends on
        local last = vim.api.nvim_buf_get_lines(buf, -2, -1, false)
            [1]
        local tail = last == "" and header.tail
            or vim.list_extend({ "" }, header.tail)
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, tail)
        return
    end

    local lines = M.plain({
        commentstring = commentstring,
        slug          = location.slug,
        fork_slug     = location.fork_slug,
        path          = location.path,
        spdx          = spdx,
        shebang       = util_shebang.get(file, buf),
        modeline      = { et = true, sw = 4, ft = vim.bo[buf].filetype },
    })

    vim.api.nvim_buf_set_lines(buf, 0, 0, false, lines)
end

--- `M.locate` of buf's file, remembered against the name it was looked up
--- for.
---
--- A lookup is up to three synchronous git spawns, and `M.apply` runs on
--- every save of every file with a header, so it is answered once per
--- buffer name. Keyed by name rather than flagged once, so a `:saveas` or
--- `:file` that moves the buffer looks again.
---@param buf  integer
---@param name string
---@return util.HeaderLocation location
local located = function(buf, name)
    ---@type { name: string, location: util.HeaderLocation }?
    local cached = vim.b[buf].cgxx_header_location
    if cached and cached.name == name then
        return cached.location
    end
    local location                  = M.locate(name)
    vim.b[buf].cgxx_header_location = { name = name, location = location }
    return location
end

--- Re-renders buf's plain-comment box for where its file now lives, if it
--- carries one, as one undo step with whatever change is being saved.
---
--- The plain counterpart of `util.frontmatter.apply`, which already does
--- the same for a Markdown header's box, so Markdown is left to it. Only
--- the box is touched: the SPDX line names a licence chosen when the file
--- was written, which a move gives no reason to revisit.
---@param buf integer
---@return nil
M.apply = function(buf)
    local commentstring = vim.bo[buf].commentstring
    local name          = vim.api.nvim_buf_get_name(buf)
    local filetype      = vim.split(vim.bo[buf].filetype, ".", {
        plain = true,
    })[1]
    if commentstring == "" or name == "" or filetype == "markdown" then
        return
    end

    -- The box opens by `box_limit` and spans at most seven lines
    local lines       = vim.api.nvim_buf_get_lines(buf, 0, box_limit + 6, false)
    local first, last = M.find_box(lines, commentstring)
    if first == nil or last == nil then
        return
    end

    local location = located(buf, name)
    local box      = M.plain_box(
        commentstring,
        location.slug,
        location.fork_slug,
        location.path
    )
    if vim.deep_equal(box, vim.list_slice(lines, first, last)) then
        return
    end

    vim.api.nvim_buf_call(buf, function()
        pcall(vim.cmd.undojoin)
    end)
    vim.api.nvim_buf_set_lines(buf, first - 1, last, false, box)
end

--- `XXInsertHeader` callback: inserts a header into the current buffer.
---@return nil
M.command = function()
    M.insert(vim.fn.expand("%"), vim.api.nvim_get_current_buf())
end

--- Registers the BufNewFile/FileType autocmd pair that defers header
--- insertion on a new file buffer until its filetype is known, and the
--- BufWritePre one that keeps an existing header's box true on save.
---@return nil
M.autocmd = function()
    vim.api.nvim_create_autocmd("BufNewFile", {
        group    = vim.api.nvim_create_augroup("cgxx.header_mark_pending", {
            clear = true,
        }),
        desc     = "Designates new file buffer for pending header insertion.",
        callback = function(opts)
            vim.b[opts.buf].cgxx_pending_header = true
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        group    = vim.api.nvim_create_augroup("cgxx.header_apply_insert", {
            clear = true,
        }),
        desc     = "Inserts templated header into new file buffer once filetype is known.",
        callback = function(opts)
            if vim.b[opts.buf].cgxx_pending_header then
                vim.b[opts.buf].cgxx_pending_header = nil
                M.insert(opts.file, opts.buf)
            end
        end,
    })

    -- Not limited to a modified buffer, unlike `util.frontmatter`'s: a
    -- moved file is typically opened and saved as is, and there is no
    -- `mtime:` here for a no-op save to bump
    vim.api.nvim_create_autocmd("BufWritePre", {
        group    = vim.api.nvim_create_augroup("cgxx.header_sync_box", {
            clear = true,
        }),
        desc     = "Re-box a plain header's repository and path on save",
        callback = function(opts)
            M.apply(opts.buf)
        end,
    })
end

--- Registers the `XXInsertHeader` user command and its supporting autocmds.
---@return nil
M.setup = function()
    vim.api.nvim_create_user_command("XXInsertHeader", M.command, {
        desc = "Prepend buffer with a header, templated according to filepath and extension.",
    })
    M.autocmd()
end

return M
