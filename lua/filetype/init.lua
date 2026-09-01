#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
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


local ft_specialised_mods = {
    man      = true,
    markdown = true,
    kdl      = true,
}
local ft_specialised = function()
    vim.api.nvim_create_autocmd("FileType", {
        desc  = "If available, instantiates filetype-specialised lua module",
        group = vim.api.nvim_create_augroup("cgxx.filetype_specialised", { clear = true }),
        callback = function(opts)
            local filetype = opts.match
            if not ft_specialised_mods[filetype] then
                return
            end

            local module = _G.require_guard(__this_module .. "." .. filetype)
            if not module then
                return 
            end

            if module.setup then
                module.setup(opts.file, opts.buf, opts)
            end
        end
    })
end

M.setup = function()
    local module = _G.require_guard(__this_module .. ".ftmatrix")
    if not module then
        return 
    end

    if module.setup then
        module.setup()
    end

    ft_specialised()
end

return M
