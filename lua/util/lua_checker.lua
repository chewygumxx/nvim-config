#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/lua_checker.lua
--
--

--
-- Tracks which type-checking backend nvim-lint runs for the "lua"
-- filetype (alongside selene), and applies switches live. Driven by the
-- XXLuaChecker user command; see usercmd.lua_checker.
--

local M = {}

---@type string[]
M.checkers = { "luals_check", "emmylua_check" }

---@type string
M.active = "luals_check"

--- The linters nvim-lint should run for "lua": selene, plus the active
--- type checker.
---@return string[]
M.linters = function()
    return { "selene", M.active }
end

--- Switches the active type checker. If nvim-lint is already loaded,
--- applies it immediately and relints the current buffer.
---@param name string One of M.checkers
---@return nil
M.set = function(name)
    if not vim.tbl_contains(M.checkers, name) then
        vim.notify(
            "Unknown lua checker: " .. name .. " (want one of: "
                .. table.concat(M.checkers, ", ") .. ")",
            vim.log.levels.ERROR
        )
        return
    end

    M.active = name

    local ok, lint = pcall(require, "lint")
    if not ok then
        return
    end
    lint.linters_by_ft.lua = M.linters()
    if vim.bo.filetype == "lua" then
        lint.try_lint()
    end
    vim.notify("Lua checker: " .. name, vim.log.levels.INFO)
end

--- Switches to the checker after the active one in M.checkers, wrapping
--- around.
---@return nil
M.toggle = function()
    for i, name in ipairs(M.checkers) do
        if name == M.active then
            M.set(M.checkers[(i % #M.checkers) + 1] or M.active)
            return
        end
    end
    M.set(M.checkers[1] or M.active)
end

return M
