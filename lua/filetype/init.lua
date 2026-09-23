#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/init.lua
--
--

--
-- Filetype module initialisation
--

local M = {}

---@type vim.filetype.add.filetypes
M.filetypes = {
    extension = {
        conf      = "dosini",
        automount = "dosini",
        device    = "dosini",
        mount     = "dosini",
        path      = "dosini",
        scope     = "dosini",
        service   = "dosini",
        slice     = "dosini",
        snapshot  = "dosini",
        socket    = "dosini",
        swap      = "dosini",
        target    = "dosini",
        timer     = "dosini",
    },

    filename = {
        ["ignore"]         = "gitignore",
        [".chezmoiignore"] = "gitignore",
        [".assetsignore"]  = "gitignore", -- CloudFlare Worker wrangler config
    },

    pattern = {
        [".*gnupg/.*%.conf"] = "gpg",
        [".*/hypr/.*%.conf"] = "hyprlang",

        [".*config/zsh/.*"]       = "zsh",
        [".*zsh/func/[^/]*"]      = "zsh",
        [".*zsh/functions/[^/]*"] = "zsh",
    },
}

--- Maps a detected filetype to the specialised module that handles it.
---@type { [string]: string } { [Filetype]: Module }
M.modmap = {
    man          = "man",
    markdown     = "markdown",
    kdl          = "kdl",
    dosini       = "dosini",
    confini      = "dosini",
    gitconfig    = "dosini",
    cfg          = "dosini",
    editorconfig = "dosini",
    gitcommit    = "prose",
    text         = "prose",
    help         = "help",
}

---@class (exact) cgxx.filetype.Module
---@field local_opts?         table<string, boolean | number | string>
---@field hlgroup_defs?       table<string, vim.api.keyset.highlight>
---@field highlights_defined? boolean
---@field setup?              fun(opts: vim.api.keyset.create_autocmd.callback_args)

---@param opts vim.api.keyset.create_autocmd.callback_args
---@return nil
M.config = function(opts)
    if type(M.modmap[opts.match]) ~= "string" then
        return
    end

    local success, module = pcall(require, "filetype." .. M.modmap[opts.match])
    if not success then
        vim.notify(
            "Filetype module for " .. opts.match
                .. " is registered but none found: filetype."
                .. M.modmap[opts.match],
            vim.log.levels.ERROR
        )
        return
    end
    ---@cast module cgxx.filetype.Module

    if type(module.local_opts) == "table" then
        local set_local = vim.opt_local --[[@as table<string, boolean | number | string>]]
        for opt, val in pairs(module.local_opts) do
            set_local[opt] = val
        end
    end

    if type(module.hlgroup_defs) == "table" and not module.highlights_defined then
        for hlgroup, defmap in pairs(module.hlgroup_defs) do
            vim.api.nvim_set_hl(0, hlgroup, defmap)
        end
        module.highlights_defined = true
    end

    if type(module.setup) == "function" then
        module.setup(opts)
    end
end

--- Registers the FileType autocmd that dispatches to a specialised
--- filetype module, if one is mapped for the triggering filetype.
---@return nil
M.autocmd = function()
    vim.api.nvim_create_autocmd("FileType", {
        desc     = "If exists, implements filetype-specific configuration",
        group    = vim.api.nvim_create_augroup("cgxx.filetype", {
            clear = true,
        }),
        callback = M.config,
    })
end

--- Sets up custom filetype detection.
---@return nil
M.setup = function()
    vim.filetype.add(M.filetypes)
end

return M
