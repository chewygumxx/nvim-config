#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/plugin.lua
--
--

--
-- Configures and arranges spec order for lazy.nvim
--

---@module "lazy"

local M = {
    elide = {
        "L3M0NAD3/LuaSnip",
        "MeanderingProgrammer/render-markdown.nvim",
        "MunifTanjim/nvim-nio",
        "OXY2DEV/markview.nvim",
        "folke/lazydev.nvim",
        "folke/noice.nvim",
        "folke/which-key.nvim",
        "jakewvincent/mkdnflow.nvim",
        "kndndrj/nvim-dbee",
        "mikavilpas/yazi.nvim",
        "nvim-telescope/telescope.nvim",
        "nvim-treesitter/nvim-treesitter-context",
        "rcarriga/nvim-notify",
        "stevearc/oil.nvim",
    },
    condemn = {
        "nvim-neorg/neorg",
        "nvim-orgmode/orgmode",
    },
}

if vim.env.TERMUX_VERSION ~= nil then
    vim.list_extend(M.condemn, {
        "mason-org/mason-lspconfig.nvim.lua",
        "jay-babu/mason-nvim-dap.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
    })
end

--- Returns a function that returns the LazySpecImport of the provided group:
--- bare `{ slug, cond/enabled = false }` overrides, merged by lazy.nvim into
--- each plugin's real spec from `{ import = "spec" }` regardless of order.
---@param group "elide" | "condemn"
---@return LazySpecImport
M.factory = function(group)
    -- Not `group == "elide" and false or nil`: the `a and b or c` idiom
    -- collapses to `c` whenever `b` is falsy, and `false` is the value
    -- we actually want here, so it always yielded nil either way.
    local field = group == "elide" and "cond" or "enabled"
    local func  = function()
        local specs = {}
        for _, slug in ipairs(M[group]) do
            table.insert(specs, { slug, [field] = false })
        end
        return specs
    end

    return { name = group, import = func }
end

---@return LazySpecImport[]
M.import = function()
    return {
        { import = "spec" },
        M.factory("elide"),
        M.factory("condemn"),
    }
end

--- Configures and arranges spec order for lazy.nvim
---@return nil
M.setup = function()
    local border_styles = {
        { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
        { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
    }

    ---@type LazyConfig
    local lazyconf = {
        spec = M.import(),
        git  = { url_format = "git@github.com:%s.git" },
        ui   = { border = border_styles[2] },
    }

    require("util.lazy").setup(lazyconf)
end

return M
