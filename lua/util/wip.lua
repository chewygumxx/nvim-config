#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/wip.lua
--
--

--
-- Periodic work-in-progress snapshots of modified buffers.
--
-- While a tracked file is being edited, its in-memory text is committed
-- onto `refs/wip/<branch>` on a debounce. Nothing observable changes:
-- HEAD, the index and the working tree are all left alone, `git status`
-- stays quiet, and `refs/wip/*` is outside the `refs/heads/*` namespace
-- so `git branch`, `git log` and `git push` ignore it by default.
--
-- Inspect and recover with plain git:
--
--   git log --oneline refs/wip/main
--   git diff refs/wip/main@{1} refs/wip/main
--   git show refs/wip/main:path/to/file.lua
--   git restore --source=refs/wip/main -- path/to/file.lua
--

local M = {}

--- Idle time in milliseconds, after a change, before a snapshot is taken.
---@type integer
M.debounce = 2000

--- Builds one commit onto `refs/wip/<branch>` from the buffer text on
--- stdin. `GIT_INDEX_FILE` is only exported once the real index has been
--- read for the blob's file mode, so every subsequent plumbing call
--- scribbles on a throwaway index instead of the one the user stages
--- into. `commit-tree` writes the object directly, which also means the
--- `pre-commit`/`commit-msg` hooks never fire for these.
---@type string
local snapshot_sh = [[
set -eu

path=$1
branch=$(git symbolic-ref --quiet --short HEAD || echo detached)
ref=refs/wip/$branch

mode=$(git ls-files --stage -- "$path" | cut -d' ' -f1)
[ -n "$mode" ] || mode=100644

blob=$(git hash-object -w --stdin)

wip=$(git rev-parse --verify --quiet "$ref" || true)
base=${wip:-$(git rev-parse --verify --quiet HEAD || true)}

GIT_INDEX_FILE=$(git rev-parse --absolute-git-dir)/cgxx-wip-index.$$
export GIT_INDEX_FILE
trap 'rm -f "$GIT_INDEX_FILE"' EXIT

if [ -n "$base" ]; then
    git read-tree "$base"
else
    git read-tree --empty
fi

git update-index --add --cacheinfo "$mode,$blob,$path"
tree=$(git write-tree)

# Nothing to record: the buffer already matches the tip of the ref
if [ -n "$base" ] && [ "$tree" = "$(git rev-parse "$base^{tree}")" ]; then
    exit 0
fi

if [ -n "$base" ]; then
    commit=$(git commit-tree "$tree" -p "$base" -m "wip($branch): $path")
else
    commit=$(git commit-tree "$tree" -m "wip($branch): $path")
fi

# The old value pins the update against a concurrent snapshot; an empty
# one asserts the ref does not exist yet
git update-ref "$ref" "$commit" "$wip"
printf '%s\n' "$ref"
]]

--- Deletes the current branch's WIP ref.
---@type string
local drop_sh = [[
set -eu

branch=$(git symbolic-ref --quiet --short HEAD || echo detached)
git update-ref -d "refs/wip/$branch"
printf 'refs/wip/%s\n' "$branch"
]]

---@type table<string, string>
local eol = {
    unix = "\n",
    dos  = "\r\n",
    mac  = "\r",
}

--- Serialises bufnr's in-memory text the way a `:write` would.
---@param bufnr integer
---@return string text
local buffer_text = function(bufnr)
    local sep   = eol[vim.bo[bufnr].fileformat] or "\n"
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local text  = table.concat(lines, sep)
    if vim.bo[bufnr].endofline or vim.bo[bufnr].fixendofline then
        text = text .. sep
    end
    return text
end

--- Resolves bufnr's worktree root and root-relative path, caching the
--- answer (ineligible buffers included) for the life of the buffer.
---@param bufnr integer
---@return string? root, string? path
local locate = function(bufnr)
    local cached = vim.b[bufnr].cgxx_wip_location
    if cached == false then
        return
    elseif cached then
        return cached[1], cached[2]
    end

    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" or vim.fn.executable("git") == 0 then
        vim.b[bufnr].cgxx_wip_location = false
        return
    end
    local dir = vim.fn.fnamemodify(name, ":p:h")

    local root = vim.system({
        "git",
        "-C",
        dir,
        "rev-parse",
        "--show-toplevel",
    }, { text = true }):wait()

    -- `--error-unmatch` is the tracked-file test: it exits nonzero for a
    -- path git has never seen, so untracked scratch files never leak
    -- into the object database
    local tracked = vim.system({
        "git",
        "-C",
        dir,
        "ls-files",
        "--full-name",
        "--error-unmatch",
        "--",
        name,
    }, { text = true }):wait()

    if root.code ~= 0 or tracked.code ~= 0
        or not root.stdout or not tracked.stdout
        or root.stdout == "" or tracked.stdout == "" then
        vim.b[bufnr].cgxx_wip_location = false
        return
    end

    local location                 = {
        (root.stdout:gsub("%s+$", "")),
        (tracked.stdout:gsub("%s+$", "")),
    }
    vim.b[bufnr].cgxx_wip_location = location
    return location[1], location[2]
end

--- Reports whether bufnr should be snapshotted at all.
---@param bufnr integer
---@return boolean eligible
local eligible = function(bufnr)
    if vim.g.cgxx_wip == false or vim.b[bufnr].cgxx_wip == false then
        return false
    end
    return vim.bo[bufnr].modifiable and vim.bo[bufnr].buftype == ""
end

--- Commits bufnr's current text onto `refs/wip/<branch>`.
---@param bufnr?  integer Default: current buffer
---@param report? boolean Notify on no-ops and ineligibility too
---@return nil
M.snapshot = function(bufnr, report)
    bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_loaded(bufnr) then
        return
    end

    local root, path = locate(bufnr)
    if not root or not path then
        if report then
            vim.notify(
                "WIP: buffer is not a tracked file",
                vim.log.levels.WARN
            )
        end
        return
    end

    vim.system(
        { "sh", "-c", snapshot_sh, "sh", path },
        {
            cwd   = root,
            stdin = buffer_text(bufnr),
            text  = true,
        },
        function(result)
            local out = (result.stdout or ""):gsub("%s+$", "")
            local err = (result.stderr or ""):gsub("%s+$", "")
            vim.schedule(function()
                if result.code ~= 0 then
                    vim.notify(
                        "WIP snapshot failed: " .. err,
                        vim.log.levels.ERROR
                    )
                elseif out == "" then
                    if report then
                        vim.notify("WIP: no change since last snapshot")
                    end
                elseif report or vim.g.cgxx_verbose then
                    vim.notify(("WIP: %s <- %s"):format(out, path))
                end
            end)
        end
    )
end

---@type table<integer, uv.uv_timer_t>
local timers = {}

--- (Re)arms bufnr's debounce timer, so a burst of typing costs one
--- snapshot once the typing stops rather than one per change.
---@param bufnr integer
---@return nil
local debounce = function(bufnr)
    local timer = timers[bufnr]
    if not timer then
        timer         = assert(vim.uv.new_timer())
        timers[bufnr] = timer
    end
    timer:stop()
    timer:start(
        M.debounce, 0,
        vim.schedule_wrap(function()
            M.snapshot(bufnr)
        end)
    )
end

--- Stops and closes bufnr's debounce timer, if it has one.
---@param bufnr integer
---@return nil
local release = function(bufnr)
    local timer = timers[bufnr]
    if not timer then
        return
    end
    timer:stop()
    timer:close()
    timers[bufnr] = nil
end

--- Enables WIP snapshots for bufnr.
---@param bufnr? integer Default: current buffer
---@return nil
M.enable = function(bufnr)
    bufnr                 = bufnr or 0
    vim.b[bufnr].cgxx_wip = true
    vim.notify("WIP snapshots: ON")
end

--- Disables WIP snapshots for bufnr, dropping any pending debounce.
---@param bufnr? integer Default: current buffer
---@return nil
M.disable = function(bufnr)
    bufnr                 = (bufnr and bufnr ~= 0) and bufnr
        or vim.api.nvim_get_current_buf()
    vim.b[bufnr].cgxx_wip = false
    release(bufnr)
    vim.notify("WIP snapshots: OFF")
end

--- Toggles WIP snapshots for bufnr.
---@param bufnr? integer Default: current buffer
---@return nil
M.toggle = function(bufnr)
    bufnr = bufnr or 0
    if vim.b[bufnr].cgxx_wip == false then
        M.enable(bufnr)
    else
        M.disable(bufnr)
    end
end

--- Deletes the WIP ref of the branch the current buffer's repository is
--- on. Destructive, hence bang-only.
---@return nil
M.drop = function()
    local root = locate(vim.api.nvim_get_current_buf())
    if not root then
        vim.notify(
            "WIP: buffer is not a tracked file",
            vim.log.levels.WARN
        )
        return
    end

    vim.system(
        { "sh", "-c", drop_sh, "sh" },
        {
            cwd  = root,
            text = true,
        },
        function(result)
            local out = (result.stdout or ""):gsub("%s+$", "")
            local err = (result.stderr or ""):gsub("%s+$", "")
            vim.schedule(function()
                if result.code ~= 0 then
                    vim.notify("WIP drop failed: " .. err, vim.log.levels.ERROR)
                else
                    vim.notify("WIP: deleted " .. out)
                end
            end)
        end
    )
end

--- Registers this module's autocmds in the "cgxx.wip" augroup.
---@return nil
M.autocmd = function()
    local group = vim.api.nvim_create_augroup("cgxx.wip", { clear = true })

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        desc     = "Debounce a WIP snapshot of the changed buffer",
        group    = group,
        callback = function(event)
            if eligible(event.buf) then
                debounce(event.buf)
            end
        end,
    })

    -- Leaving or saving is a natural checkpoint, and is near free: an
    -- unchanged tree never reaches `commit-tree`
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufLeave", "FocusLost" }, {
        desc     = "Take a WIP snapshot at an editing checkpoint",
        group    = group,
        callback = function(event)
            -- A write can make a previously untracked file eligible
            if event.event == "BufWritePost" then
                vim.b[event.buf].cgxx_wip_location = nil
            end
            if eligible(event.buf) then
                M.snapshot(event.buf)
            end
        end,
    })

    vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        desc     = "Release the buffer's WIP debounce timer",
        group    = group,
        callback = function(event)
            release(event.buf)
        end,
    })
end

---@type table<string, fun(bang: boolean)>
local act_func = {
    toggle   = function(_)
        M.toggle()
    end,
    enable   = function(_)
        M.enable()
    end,
    disable  = function(_)
        M.disable()
    end,
    snapshot = function(_)
        M.snapshot(nil, true)
    end,
    drop     = function(bang)
        if not bang then
            vim.notify(
                "WIP: `XXWip drop` deletes history, use `XXWip! drop`",
                vim.log.levels.WARN
            )
            return
        end
        M.drop()
    end,
}

--- `nvim_create_user_command` callback backing `XXWip`.
---@param opts vim.api.keyset.create_user_command.command_args
---@return nil
M.command = function(opts)
    local act = opts.fargs[1] or "toggle"
    local fn  = act_func[act]
    if not fn then
        vim.notify("XXWip: unknown action " .. act, vim.log.levels.ERROR)
        return
    end
    fn(opts.bang)
end

--- `nvim_create_user_command` completion for `XXWip`.
---@return string[] actions
M.complete = function()
    return vim.fn.sort(vim.tbl_keys(act_func))
end

return M
