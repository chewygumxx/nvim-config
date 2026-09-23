#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/spec/init.lua
--
--

--
-- Exported LazySpecImport[] module `M` at EOF
--

---@module "lazy"

local M = {
    __this_module = ...,
}

--- Module directory, trailing path separator is handled with vim.fs.joinpath()
--- Read via debug.getinfo() rather than package.searchpath(), since this
--- chunk is also loaded directly by lazy.nvim's own directory scan (see
--- M.import()), which calls it with no varargs.
M.__this_moddir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))

--- Groups of module filepaths relative to this module (.lua excluded)
---@enum (key) cgxx.spec.group
M.groups = {
    colorscheme = { "starry" },
    essential   = {
        "blink.cmp",
        "claudecode.nvim",
        "conform.nvim",
        "nvim-treesitter",
    },
    base        = {
        "comment.nvim",
        "gist.nvim",
        "mini.hipatterns",
    },
    devtool     = {
        "fidget.nvim",
        "mason-nvim-dap.nvim",
        "mason-tool-installer.nvim",
        "mason.nvim",
        "mini.test",
        "nvim-lint",
        "nvim-lspconfig",
        "one-small-step-for-vimkind",
    },
    filetype    = {
        "kdl",
        "nvim-jqx",
        "schemastore.nvim",
    },
    verylazy    = {
        "mini.files",
        "oil.nvim",
        "store.nvim",
    },
    niche       = {
        "herdr-nvim",
        "nvim-dbee",
        "nvim-unception",
        "wezterm-types",
    },
    trial       = {
        "fzf-lua",
        "harpoon",
        "mini.icons",
        "noice.nvim",
        "nvim-dap",
        "nvim-dap-ui",
        "snacks.nvim",
        "telescope-undo",
        "telescope.nvim",
        "which-key.nvim",
        "yazi.nvim",
    },
    elide       = {
        "lazydev.nvim",
        "luasnip",
        "markview.nvim",
        "mkdnflow",
        "nvim-notify",
        "nvim-treesitter-context",
        "render-markdown.nvim",
    },
    condemn     = {
        "mkdnflow",
        "neorg",
        "orgmode",
    },
}

---@param modpath     string Module path under /lua/spec/
---@param import_name string Name of caller import spec
---@return LazyPluginSpec spec Resolved plugin spec
M.dummy = function(modpath, import_name)
    local filepath = vim.fs.joinpath(M.__this_moddir, modpath .. ".lua")
    vim.notify(
        string.format(
            "spec_guard: Failed to resolve %s of %s:\n%s",
            modpath,
            import_name,
            filepath
        ),
        vim.log.levels.ERROR
    )
    return {
        string.format("chewygumxx/Err_%s_%s", import_name, modpath),
        name = string.format("Not found: [%s] %s", import_name, filepath),
        cond = false,
    }
end

--- Spec-Specialised Dofile Guard
--- Success, returns spec. Failure, vim.notify() and tracable dummy spec.
---@param modpath     string Module path under /lua/spec/
---@param import_name string Name of caller import spec
---@return LazyPluginSpec spec Resolved plugin spec
M.guard = function(modpath, import_name)
    -- dofile > require for `.` filenam handling
    local success, spec = pcall(
        dofile,
        vim.fs.joinpath(
            M.__this_moddir,
            modpath .. ".lua"
        )
    )
    if not success then
        return M.dummy(modpath, import_name)
    end
    return spec
end

--- Returns a that returns the LazySpecImport of the provided group
---@param group cgxx.spec.group
---@return LazySpecImport
M.factory = function(group)
    local func = function()
        local specs = {}
        for _, filepath in ipairs(M.groups[group]) do
            local spec = M.guard(filepath, group)
            if type(spec) == "table" then
                spec.cond    = group == "elide" and false or nil
                spec.enabled = group == "condemn" and false or nil
                table.insert(specs, spec)
            end
        end
        return specs
    end
    return { name = group, import = func }
end

---@return LazySpecImport[]
M.import = function()
    return {
        { import = M.__this_module },
        M.factory("colorscheme"),
        M.factory("elide"),
        M.factory("condemn"),
    }
end

return M
