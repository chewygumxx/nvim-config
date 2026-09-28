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

--- Indent carried by every line inside the `__cgxx:` block scalar. Two
--- spaces because that is what YAML needs to keep them in the block, and
--- because `.editorconfig` gives Markdown the same.
---@type string
local block_indent = "  "

--- Width the folded `description:` scalar wraps at, indent included.
---@type integer
local description_width = 80

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

---@class util.FrontmatterOpt
---@field title        string   Heading, and the `title:` key
---@field slug?        string   Repository, boxed as `~slug.git`
---@field fork_slug?   string   Fork of slug, boxed beneath it
---@field path?        string   Repo-relative path, boxed after `::: `
---@field spdx?        string   SPDX identifier; the line is omitted without one
---@field filetype?    string   Modeline `filetype` (default: "markdown")
---@field shiftwidth?  integer  Modeline `shiftwidth` (default: 2)
---@field foldlevel?   integer  Modeline `foldlevel`; omitted without one
---@field description? string   Body of the folded `description:` scalar
---@field tags?        string[] `tags:` block sequence, in the order given
---@field ctime?       string   YYYY-MM-DD (default: today)

--- Renders a Markdown file's YAML frontmatter, opening `---` to closing
--- `---` inclusive.
---
--- The modeline and the boxed repository notation live inside a `__cgxx: |`
--- literal block scalar rather than above the frontmatter, so that a file
--- opens with both a valid YAML document at its head and a modeline Vim
--- still reads. Inside that block the comment syntax is the frontmatter's
--- own (`# %s`) and not the buffer's, which is why nothing here consults
--- 'commentstring'.
---
--- Shared with `util.nex`, which renders the same shape for a note: this is
--- the one description of the format, so a change here reaches both.
---@param opt util.FrontmatterOpt
---@return string[] lines
M.frontmatter = function(opt)
    local title         = opt.title
    local ctime         = opt.ctime or tostring(os.date("%Y-%m-%d"))
    local description   = opt.description or ""
    local tags          = opt.tags or {}
    local commentstring = "# %s"

    local modeline = util_modeline.base({
        et            = true,
        sw            = opt.shiftwidth or 2,
        ft            = opt.filetype or "markdown",
        append        = opt.foldlevel
            and " foldlevel=" .. tostring(opt.foldlevel)
            or nil,
        commentstring = commentstring,
    })

    ---@type string[]
    local lines = {
        "---",
        "__cgxx: |",
        block_indent .. modeline,
    }

    if opt.spdx then
        -- Hoisted rather than inlined into the call: `luafmt --verify`
        -- reports the two-argument form here as non-idempotent, laying it
        -- out differently on each pass
        local identifier  = "SPDX-License-Identifier: " .. opt.spdx
        lines[#lines + 1] = block_indent
            .. string.format(commentstring, identifier)
    end

    vim.list_extend(lines, {
        "",
        block_indent .. string.format(commentstring, ""),
        block_indent .. string.format(commentstring, ""),
    })

    if opt.slug then
        lines[#lines + 1] = block_indent
            .. string.format(commentstring, "~" .. opt.slug .. ".git")
        if opt.fork_slug then
            lines[#lines + 1] = block_indent
                .. string.format(
                    commentstring,
                    "└─> ~" .. opt.fork_slug .. ".git"
                )
        end
    end

    if opt.path then
        lines[#lines + 1] = block_indent
            .. string.format(
                commentstring,
                opt.slug and "::: " .. opt.path or opt.path
            )
    end

    vim.list_extend(lines, {
        block_indent .. string.format(commentstring, ""),
        block_indent .. string.format(commentstring, ""),
        "",
        "ctime: " .. ctime,
        "title: " .. util_text.yaml_scalar(title),
    })

    -- A folded ">-" scalar cannot hold an empty body: YAML would read the
    -- next key as its content. Fall back to an empty flow scalar.
    if description == "" then
        lines[#lines + 1] = 'description: ""'
    else
        lines[#lines + 1] = "description: >-"
        vim.list_extend(
            lines,
            util_text.wrap_comment(description, description_width, {
                commentstring = block_indent .. "%s",
            })
        )
    end

    if #tags == 0 then
        lines[#lines + 1] = "tags: []"
    else
        lines[#lines + 1] = "tags:"
        for _, tag in ipairs(tags) do
            lines[#lines + 1] = block_indent .. "- "
                .. util_text.yaml_scalar(tag)
        end
    end

    lines[#lines + 1] = "---"

    return trim_lines(lines)
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
        lines[#lines + 1] = string.format(commentstring, "")
        lines[#lines + 1] = string.format(commentstring, "")
        if opt.slug then
            lines[#lines + 1] = string.format(
                commentstring,
                "~" .. opt.slug .. ".git"
            )
            if opt.fork_slug then
                lines[#lines + 1] = string.format(
                    commentstring,
                    "└─> ~" .. opt.fork_slug .. ".git"
                )
            end
            lines[#lines + 1] = string.format(
                commentstring,
                "::: " .. opt.path
            )
        else
            lines[#lines + 1] = string.format(commentstring, opt.path)
        end
        lines[#lines + 1] = string.format(commentstring, "")
        lines[#lines + 1] = string.format(commentstring, "")
    end

    lines[#lines + 1] = ""

    return trim_lines(lines)
end

---@class util.HeaderInsertOpt
---@field commentstring? string Commentstring override

--- Prepends buf with a templated header (modeline, SPDX line, repo slug
--- and path), then Markdown frontmatter if buf's filetype is "markdown".
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

    -- (Slug and) Path
    ---@type string?
    local slug
    ---@type string?
    local upstream_slug
    local path = util_git.path(file)
    if path:find(":", 1, true) == 1 then
        slug          = util_git.slug(file)
        upstream_slug = util_git.slug(file, "upstream")
    end
    if path:find("~/.config", 1, true) == 1 then
        slug = "chewygumxx/dotfiles"
        path = path:gsub("~/%.config", ":/dot_config")
    end

    -- License. This repository's own unless the file belongs to a fork, in
    -- which case the upstream's; a lookup that fails says so rather than
    -- falling back to ours. `NOASSERTION` is SPDX's own word for "not
    -- determined", so the header stays valid and the gap stays visible.
    local spdx = "GPL-3.0-only"
    if upstream_slug then
        local upstream_spdx = util_git.license(upstream_slug)
        if not upstream_spdx then
            vim.notify(
                "Header: no licence found for " .. upstream_slug
                    .. "; wrote NOASSERTION",
                vim.log.levels.WARN
            )
        end
        spdx = upstream_spdx or "NOASSERTION"
    end

    --
    -- Markdown is a different document, not a differently commented one:
    -- the modeline, the SPDX line and the box all move inside a `__cgxx: |`
    -- block scalar, so `M.frontmatter` renders the whole thing rather than
    -- this function interleaving it with the plain-comment case.
    --
    -- Compound filetypes are deliberately excluded by the equality check:
    -- a `markdown.nex-note` buffer is `util.nex`'s to render, and a
    -- `markdown.claude` one carries no repository frontmatter at all.
    --
    if vim.bo[buf].filetype == "markdown" then
        local lines = M.frontmatter({
            -- The upstream is named first and the fork beneath it, so the
            -- fork's own slug is what moves to `fork_slug`
            slug      = upstream_slug or slug,
            fork_slug = upstream_slug and slug or nil,
            path      = path,
            spdx      = spdx,
            foldlevel = markdown_foldlevel,
            title     = title_placeholder,
        })
        vim.list_extend(lines, { "", "# " .. title_placeholder, "" })
        vim.api.nvim_buf_set_lines(buf, 0, 0, false, lines)
        return
    end

    -- As in the Markdown branch above, the upstream is named first and the
    -- fork beneath it, so the fork's own slug is what moves to `fork_slug`
    local lines = M.plain({
        commentstring = commentstring,
        slug          = upstream_slug or slug,
        fork_slug     = upstream_slug and slug or nil,
        path          = path,
        spdx          = spdx,
        shebang       = util_shebang.get(file, buf),
        modeline      = { et = true, sw = 4, ft = vim.bo[buf].filetype },
    })

    vim.api.nvim_buf_set_lines(buf, 0, 0, false, lines)
end

--- `XXInsertHeader` callback: inserts a header into the current buffer.
---@return nil
M.command = function()
    M.insert(vim.fn.expand("%"), vim.api.nvim_get_current_buf())
end

--- Registers the BufNewFile/FileType autocmd pair that defers header
--- insertion on a new file buffer until its filetype is known.
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
