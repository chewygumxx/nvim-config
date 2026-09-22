#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/keymap/gx.lua
--
--

local M = {
    desc = "Open URL or owner/repo under cursor",
}

---@class (exact) cgxx.keymap.gx.pattern_map
---@field pattern   string    Regex
---@field url       string    URL String Format
---@field filetypes string[]? Filetypes

---@type cgxx.keymap.gx.pattern_map[]
M.pattern_maps = {
    {
        -- slug = "owner/repo"
        pattern = 'slug%s*=%s*["\']([%w-]+/[%w_.-]+)["\']',
        url = "https://github.com/%s",
    },
    {
        -- any quoted "owner/repo", e.g. lazy.nvim plugin specs
        pattern = '["\']([%w-]+/[%w_.-]+)["\']',
        url = "https://github.com/%s",
        filetypes = { "lua" },
    },
}

---@return string?
M.url_at_cursor = function()
    local line = vim.api.nvim_get_current_line()
    local col  = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 0-based -> 1-based

    for _, map in ipairs(M.pattern_maps) do
        if not map.filetypes or vim.tbl_contains(map.filetypes, vim.bo.filetype) then
            local init = 1
            while true do
                local start, finish, repo = line:find(map.pattern, init)
                if not start then
                    break
                end
                -- Only fire when the cursor sits inside the whole match
                if col >= start and col <= finish then
                    return map.url:format(repo)
                end
                init = finish + 1
            end
        end
    end
end

---@return nil
M.callback = function()
    local url = M.url_at_cursor()
    if not url then
        if M.fallback and M.fallback.callback then
            return M.fallback.callback()
        end
        url = vim.fn.expand("<cfile>")
    end

    local _, err = vim.ui.open(url)
    if err then
        vim.notify(err, vim.log.levels.ERROR)
    end
end

---@return nil
M.setup = function()
    --- Idempotency Guard
    --- Resolve the callback of the Neovim builtin keymap
    --- Protects against infinite self-assigned fallback recursion by utilising desc
    --- as a unique identifier.
    ---@type vim.api.keyset.get_keymap
    local current = vim.fn.maparg("gx", "n", false, true)
    if current.desc ~= M.desc then
        M.fallback = current
    end

    vim.keymap.set("n", "gx", M.callback, { desc = M.desc })
end

return M
