#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- luacheck: globals vim

--
--
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/filetype/init.lua
--
--

--
-- Filetype module initialisation
--

local M = {}
local __this_module = ...


-- Maps a detected filetype to the specialised module that handles it.
-- Several real filetypes can share one module (e.g. the various ini-syntax
-- filetypes Neovim assigns distinct names to all route to "dosini").
local ft_specialised_mods = {
    man          = "man",
    markdown     = "markdown",
    kdl          = "kdl",
    dosini       = "dosini",
    confini      = "dosini",
    gitconfig    = "dosini",
    cfg          = "dosini",
    editorconfig = "dosini",
}
local ft_specialised = function()
    vim.api.nvim_create_autocmd("FileType", {
        desc  = "If available, instantiates filetype-specialised lua module",
        group = vim.api.nvim_create_augroup("cgxx.filetype_specialised", { clear = true }),
        callback = function(opts)
            local modname = ft_specialised_mods[opts.match]
            if not modname then
                return
            end

            local module = _G.require_guard(__this_module .. "." .. modname)
            if not (module and module.setup) then
                return
            end

            module.setup(opts.file, opts.buf, opts)
        end
    })
end

M.setup = function()
    _G.setup_guard(__this_module .. ".ftmatrix")
    ft_specialised()
end

return M
