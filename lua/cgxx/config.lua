#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/cgxx/config.lua
--
--

--
-- Default values of cgxx module
--

local M = {}

-- Filetype to lsp preference map
---@class cgxx.config.lsp
---@field markdown nil | "markdown_oxide" | "marksman" | "remark_ls"
---@field lua      nil | "lua_ls" | "emmylua_ls"

---@module "lazy"
---@class cgxx.config.lazy
---@field default_spec nil | LazySpec
-- If function, returns a local plugin directory
---@field devpath      nil | false | string | fun(plugin: LazyPlugin): string
---@field checker      nil | boolean
-- Comprehensive loader and require() profiling
---@field profile      nil | boolean
---@field readme       nil | boolean                                          Generate doc from README when none
---@field watch_config nil | boolean                                          Watch config file to update UI on change

---@class cgxx.config Default
---@field lsp         nil | cgxx.config.lsp
---@field fuzzy       nil | "fzf-lua" | "telescope.nvim"
---@field colorscheme nil | string | string[]
---@field lazy        nil | cgxx.config.lazy

---@type cgxx.config
M.config = {
    lsp   = {
        markdown = "markdown_oxide",
        lua      = "lua_ls",
    },
    fuzzy = "fzf-lua",
    lazy  = {
        default_spec = { lazy = false },
        devpath      = false,
        checker      = false,
        profile      = false,
        readme       = true,
        watch_config = false,
    },

    colorscheme = { "middlenight_blue", "elflord" },
}

---@param opts cgxx.config
---@return cgxx.config
M.setup = function(opts)
    return vim.tbl_deep_extend("force", vim.deepcopy(M.config), opts)
end

return M
