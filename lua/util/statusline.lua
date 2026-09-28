#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/statusline.lua
--
--

--
-- Git-aware file identification for the statusline.
--
-- Replaces the leading `%f` of Neovim's default 'statusline' with the same
-- repository notation this config writes into its own file headers (see
-- `util.header`):
--
--   ~chewygumxx/nvim-config.git:bufferline-git:/lua/util/statusline.lua
--
-- The path's tail alone is ambiguous across checkouts and worktrees of one
-- project; the slug and branch disambiguate them.
--
-- Three decisions here are load-bearing.
--
-- Each part of that notation is coloured separately, by
-- `CgxxStatuslineSlug`, `CgxxStatuslineBranch` and `CgxxStatuslinePath`
-- (defined in `lua/highlight.lua`), which is why `M.items` holds three
-- items rather than one. The colour lives in the format string and never in
-- what a callback returns, for the reason immediately below.
--
-- The segment is a plain `%{}`, never the nested `%{%...%}` form. Only the
-- latter re-parses its result for statusline items, which silently mangles
-- any "%" in a filename or branch name: a buffer named `we%ird%%.lua`
-- renders as `werd%.lua` through `%{%...%}` ("%i" eaten as an item, "%%"
-- collapsed) but survives intact through `%{}`. As a bonus, nothing needs
-- escaping.
--
-- Where no segment applies, the fallback is a second item that emits the
-- literal string "%f" for Neovim to expand, rather than this module
-- reproducing it. `%f` is not `nvim_buf_get_name`: it also supplies the
-- bracketed names of special buffers and shortens against the home
-- directory and the cwd. Measured:
--
--   buffer     %f                buf_get_name
--   :copen     [Quickfix List]   ""
--   :help      helphelp.txt      /usr/share/nvim/runtime/doc/helphelp.txt
--   :enew      [No Name]         ""
--
-- Re-implementing that in Lua would be a fidelity bug per buffer type, so
-- the real thing is deferred to. This is the one place the re-parsing item
-- form is used, and it only ever re-parses that one constant -- never a
-- filename, a branch, or anything else outside this file.
--
-- Nothing in the render path ever calls git, and nothing anywhere blocks
-- on it. A statusline is re-evaluated on essentially every keystroke and
-- cursor move, in every window, so `M.segment` is a cache read; a miss
-- schedules the resolve and falls back to `%f` for that one redraw, and the
-- resolve itself is a single async `util.git.info` call. Filling lazily on
-- miss, rather than on `BufEnter`, means a buffer displayed by any route at
-- all -- a plugin's `nvim_open_win`, a float, a restored session, a diff
-- window -- fills itself in, leaving autocmds responsible only for
-- invalidation.
--

local M = {}

local util_git = require("util.git")

--- Buffers whose resolve has been started but not finished, keyed by buffer
--- number: `true` once scheduled, then the buffer name the in-flight git
--- call was issued for, which is what lets a late callback recognise that
--- it has been superseded.
---
--- Deliberately a module-local table rather than a `vim.b` variable:
--- `M.segment` runs during statusline evaluation, which is the wrong place
--- to be mutating buffer state, so it only ever reads `vim.b` and writes
--- here.
---@type table<integer, true | string>
local pending = {}

--- Stands in for the slug of a repository without an "origin" remote.
---@type string
local no_slug = "<local>"

--- Stands in for the branch of a repository with a detached HEAD, as
--- `util.wip`'s snapshot ref names already do.
---@type string
local no_branch = "detached"

--- The statusline item Neovim expands into the buffer's filename, emitted
--- verbatim whenever no git segment applies.
---@type string
local filename_item = "%f"

--- Splits a cached segment into the three parts the statusline colours
--- separately. Each keeps the separator that follows it, so nothing has to
--- be emitted between the items: a separator sitting in the format string
--- would render even when there is no segment, ie. beside the `%f`
--- fallback.
---
--- Left to right on ":" is unambiguous for what `compose` builds, despite
--- looking as though it should not be. git forbids ":" in a ref name and a
--- slug cannot hold one either, so the first two colons are structural and
--- every later one belongs to the filename. A value that is not that
--- notation at all, ie. the `:~` filename `resolve` falls back to for a
--- file outside any repository, is left whole as the path: it may
--- legitimately begin with anything, so splitting it would be guesswork.
---@param value string
---@return string slug   Repository and its separator, or ""
---@return string branch Branch name, or ""
---@return string path   `:/`-prefixed repository path, or the whole value
local split = function(value)
    local first = value:find(":", 1, true)
    if not first then
        return "", "", value
    end

    local head = value:sub(1, first - 1)
    if head ~= no_slug and not head:match("^~.+%.git$") then
        return "", "", value
    end

    local second = value:find(":", first + 1, true)
    if not second then
        return "", "", value
    end

    return value:sub(1, first),
        value:sub(first + 1, second - 1), value:sub(second)
end

--- Composes the segment for name from its repository's info.
---@param info cgxx.git.info
---@param name string        Absolute buffer name
---@return string segment
local compose = function(info, name)
    -- `util.git.path`'s notation, reproduced from the parts so that this
    -- and `util.header` keep saying the same thing about a file
    local path   = ":/" .. info.prefix .. vim.fn.fnamemodify(name, ":t")
    local branch = info.branch ~= "" and info.branch or no_branch

    if not info.slug then
        return no_slug .. ":" .. branch .. path
    end
    return "~" .. info.slug .. ".git:" .. branch .. path
end

--- Caches bufnr's segment and redraws, if it actually changed.
---@param bufnr integer
---@param value string | false
---@return nil
local store = function(bufnr, value)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    -- Gating the redraw on an actual change is what keeps this from
    -- feeding itself: a redraw re-evaluates the statusline, which is what
    -- schedules resolves in the first place, so redrawing unconditionally
    -- turns any buffer appearing mid-redraw into a livelock.
    if vim.b[bufnr].cgxx_statusline == value then
        return
    end
    vim.b[bufnr].cgxx_statusline = value

    -- "!" redraws every window's statusline, not just the current one, so
    -- a split resolving in the background updates too
    vim.cmd("redrawstatus!")
end

--- Resolves and caches bufnr's segment: the ineligible cases decided here
--- and now, the repository lookup handed to one async git call.
---@param bufnr integer
---@return nil
local resolve = function(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        pending[bufnr] = nil
        return
    end

    local name = vim.api.nvim_buf_get_name(bufnr)

    -- A nameless buffer has no file to locate, and a special buffer
    -- (help, oil, fzf-lua, terminal, quickfix, ...) names something that
    -- isn't one. A URI-named buffer whose plugin left `buftype` empty is
    -- the same case wearing a path's clothing. All are left to `%f`.
    if name == "" or vim.bo[bufnr].buftype ~= ""
        or name:match("^%a[%w+.%-]*://") then
        pending[bufnr] = nil
        store(bufnr, false)
        return
    end

    -- Captured so the callback can tell whether it is still wanted
    pending[bufnr] = name

    util_git.info(name, function(info)
        -- A rename or a refresh mid-flight supersedes this answer. Without
        -- the check, a late callback would overwrite the newer segment
        -- with one composed for the name this buffer used to have.
        if pending[bufnr] ~= name then
            return
        end
        pending[bufnr] = nil

        if not vim.api.nvim_buf_is_valid(bufnr)
            or vim.api.nvim_buf_get_name(bufnr) ~= name then
            return
        end

        store(
            bufnr,
            info and compose(info, name) or vim.fn.fnamemodify(name, ":~")
        )
    end)
end

--- Forgets bufnr's in-flight marker.
---@param bufnr integer
---@return nil
local release = function(bufnr)
    pending[bufnr] = nil
end

--- bufnr's cached segment, if it has resolved to one.
---@param bufnr integer
---@return string? segment nil while unresolved, or if none applies
local cached = function(bufnr)
    local value = vim.b[bufnr].cgxx_statusline
    if type(value) ~= "string" then
        return
    end
    return value
end

--- Resolves a `%{}` callback's buffer argument.
---@param bufnr? integer
---@return integer bufnr
local target = function(bufnr)
    return (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
end

--- 'statusline' `%{}` callback: bufnr's cached git segment, or "" when
--- there is none to show yet. Pairs with `M.fallback`.
---
--- Evaluated in the context of the window being drawn, so the default of
--- the current buffer is that window's buffer.
---@param bufnr? integer Default: current buffer
---@return string segment
M.segment = function(bufnr)
    bufnr = target(bufnr)

    local value = cached(bufnr)
    if value then
        return value
    end

    if not pending[bufnr] then
        pending[bufnr] = true
        vim.schedule(function()
            resolve(bufnr)
        end)
    end
    return ""
end

--- 'statusline' `%{}` callback: the repository part of bufnr's segment,
--- separator included, or "" when there is none. Pairs with `M.branch` and
--- `M.path`, which are the same read of the same cache.
---@param bufnr? integer Default: current buffer
---@return string slug
M.slug = function(bufnr)
    local slug = split(M.segment(bufnr))
    return slug
end

--- 'statusline' `%{}` callback: the branch part of bufnr's segment, or ""
--- when there is none.
---@param bufnr? integer Default: current buffer
---@return string branch
M.branch = function(bufnr)
    local _, branch = split(M.segment(bufnr))
    return branch
end

--- 'statusline' `%{}` callback: the path part of bufnr's segment, or ""
--- when there is none. Carries the whole value for a file outside any
--- repository, which has neither of the other two parts.
---@param bufnr? integer Default: current buffer
---@return string path
M.path = function(bufnr)
    local _, _, path = split(M.segment(bufnr))
    return path
end

--- 'statusline' `%{%...%}` callback: the literal `%f` item whenever
--- `M.segment` has nothing to show, so Neovim renders the filename itself.
---@param bufnr? integer Default: current buffer
---@return string item `"%f"`, or "" when a git segment is being shown
M.fallback = function(bufnr)
    return cached(target(bufnr)) and "" or filename_item
end

--- Drops bufnr's cached segment, so the next redraw resolves it again.
---@param bufnr? integer Default: current buffer
---@return nil
M.refresh = function(bufnr)
    bufnr = target(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    vim.b[bufnr].cgxx_statusline = nil
    release(bufnr)
    vim.cmd("redrawstatus!")
end

--- Drops every loaded buffer's cached segment. For a change of git state
--- that is global rather than per-buffer, ie. a checkout.
---@return nil
M.refresh_all = function()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
            vim.b[bufnr].cgxx_statusline = nil
            release(bufnr)
        end
    end
    vim.cmd("redrawstatus!")
end

--- Registers this module's invalidation autocmds in the "cgxx.statusline"
--- augroup.
---
--- Only invalidation: the segment itself fills in lazily on a cache miss,
--- so no event has to be responsible for a buffer becoming visible.
--- `DirChanged` is deliberately absent, since every answer is anchored to
--- the file's own directory via `git -C` and never to the cwd.
---@return nil
M.autocmd = function()
    local group = vim.api.nvim_create_augroup("cgxx.statusline", {
        clear = true,
    })

    -- A rename keeps the buffer number, so nothing else would notice that
    -- the slug, prefix and filename have all potentially changed
    vim.api.nvim_create_autocmd({ "BufFilePost", "BufWritePost" }, {
        desc     = "Invalidate the buffer's cached statusline git segment",
        group    = group,
        callback = function(event)
            M.refresh(event.buf)
        end,
    })

    -- How the branch usually goes stale: a checkout elsewhere, either in
    -- another terminal, a suspended session, or an embedded one
    vim.api.nvim_create_autocmd({
        "FocusGained",
        "VimResume",
        "ShellCmdPost",
        "TermClose",
    },
        {
            desc     = "Invalidate every cached statusline git segment",
            group    = group,
            callback = function()
                M.refresh_all()
            end
        })

    vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        desc     = "Release the buffer's statusline resolve marker",
        group    = group,
        callback = function(event)
            release(event.buf)
        end,
    })
end

--- The statusline items this module contributes, in place of `%f`.
---
--- Three `%{}` items rather than one, because colour cannot come from the
--- data. A `%#Group#` only takes effect where the statusline is parsed for
--- items, and the values here are deliberately never re-parsed (see the
--- header), so the highlight items sit in this format string *between* the
--- three calls and every value stays unparsed. Each is a cache read, and
--- the first of them schedules the resolve the other two then find.
---
--- `%*` and not `%#StatusLine#` to close: the reset has to restore
--- whichever group this window's statusline already had, which is
--- `StatusLineNC` in every window that is not the current one.
---@type string
M.items = "%<"
    .. "%#CgxxStatuslineSlug#%{v:lua.require'util.statusline'.slug()}"
    .. "%#CgxxStatuslineBranch#%{v:lua.require'util.statusline'.branch()}"
    .. "%#CgxxStatuslinePath#%{v:lua.require'util.statusline'.path()}"
    .. "%*"
    .. "%{%v:lua.require'util.statusline'.fallback()%}"

--- 'statusline' with this module's items spliced in over the leading
--- `%<%f` of Neovim's default.
---
--- That default is not empty: past `%f` it carries the terminal exit code,
--- LSP progress, `showcmd`, `b:keymap_name`, the busy spinner,
--- `vim.diagnostic.status()` and the ruler. Assigning a hand-written value
--- would silently drop all of that, so the default is read back from the
--- option itself and only its filename item replaced -- which also avoids
--- pinning a copy of it that would rot across releases. Reading `.default`
--- rather than the live value also makes this idempotent: it can never
--- splice into its own output.
---
--- The leading `%<` is kept: it is the truncation marker, so a long
--- repository path shortens from the left in a narrow window, preserving
--- the filename at the tail.
---@return string statusline
M.value = function()
    local info = vim.api.nvim_get_option_info2("statusline", {})
    -- `nvim_get_option_info2` types `default` as any option's value type,
    -- ie. `string|integer|boolean`; 'statusline' is always a string, so
    -- `tostring` narrows it without a cast and changes nothing at runtime
    local default = tostring(info.default)
    local leader  = "%<%f"

    -- Plain `find`, and concatenation rather than `gsub`: the leader is a
    -- Lua pattern's worth of magic characters, and the replacement holds
    -- "%{", which `gsub` would read as a capture reference
    local at = default:find(leader, 1, true)
    if not at then
        -- Degrade rather than error should a future Neovim word its
        -- default differently; the tests catch it loudly instead
        return M.items .. " " .. default
    end
    return default:sub(1, at - 1) .. M.items .. default:sub(at + #leader)
end

--- Installs this module's 'statusline'.
---@return nil
M.setup = function()
    vim.api.nvim_set_option_value("statusline", M.value(), {})
end

return M
