#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/keymap/init.lua
--
--

--
-- Neovim configuration of keymaps
--

local M = {}

vim.g.mapleader  = "\\"
vim.o.timeoutlen = 1000 -- Time to complete keymap sequence
vim.o.showcmd    = true -- Show keystrokes right of message buffer

--- Maps lhs to `:noh` (clear search highlight).
---@param lhs?  string Default: "<leader>h"
---@param desc? string Default: ":noh - Clear highlight of search match"
---@return nil
M.clear_hlsearch = function(lhs, desc)
    lhs  = lhs or "<leader>h"
    desc = desc or ":noh - Clear highlight of search match"
    vim.keymap.set({ "n" }, lhs, "<cmd>noh<CR>", { desc = desc })
end

--- Maps lhs to toggle `relativenumber` persistently.
---@param lhs?  string Default: "<leader>rn"
---@param desc? string Default: "Toggle relativenumber"
---@return nil
M.toggle_relativenumber = function(lhs, desc)
    lhs  = lhs or "<leader>rn"
    desc = desc or "Toggle relativenumber"
    vim.keymap.set({ "n" }, lhs, function()
        vim.o.relativenumber = not vim.o.relativenumber
    end, { desc = desc }
    )
end

--- Maps lhs to flip `relativenumber` for 2 seconds, then restore it.
---@param lhs?  string Default: "<leader>nn"
---@param desc? string Default: "Blink relativenumber"
---@return nil
M.blink_relativenumber = function(lhs, desc)
    lhs  = lhs or "<leader>nn"
    desc = desc or "Blink relativenumber"
    vim.keymap.set("n", lhs, function()
        local old_relativenumber = vim.o.relativenumber
        vim.o.relativenumber     = not old_relativenumber
        vim.defer_fn(function()
            vim.o.relativenumber = old_relativenumber
        end, 2000)
    end, { desc = desc }
    )
end

--- Maps lhs to highlight the absolute line number gutter as `ErrorMsg`
--- for 3 seconds, then restore `number`/`relativenumber`/`LineNr`.
---@param lhs?  string Default: "<leader>ln"
---@param desc? string Default: "Blink line number in gutter"
---@return nil
M.blink_linenumber = function(lhs, desc)
    lhs  = lhs or "<leader>ln"
    desc = desc or "Blink line number in gutter"
    vim.keymap.set({ "n" }, lhs, function()
        local old_o_number         = vim.o.number
        local old_o_relativenumber = vim.o.relativenumber
        local old_hl_linenr        = vim.api.nvim_get_hl(0, { name = "LineNr" })

        vim.api.nvim_set_hl(0, "LineNr", { link = "ErrorMsg" })
        vim.o.number         = true
        vim.o.relativenumber = false

        vim.defer_fn(function()
            vim.api.nvim_set_hl(
                0,
                "LineNr",
                old_hl_linenr --[[@as vim.api.keyset.highlight]]
            )
            vim.o.number         = old_o_number
            vim.o.relativenumber = old_o_relativenumber
        end, 3000)
    end, { desc = desc }
    )
end

--- Maps lhs to reflow the whole buffer at `textwidth` (`gggqG`).
---@param lhs?  string Default: "<leader>tw"
---@param desc? string Default: "Format buffer line wrapping according to
---  textwidth"
---@return nil
M.format_buffer = function(lhs, desc)
    lhs  = lhs or "<leader>tw"
    desc = desc or "Format buffer line wrapping according to textwidth"
    vim.keymap.set({ "n" }, lhs, "gggqG", { desc = desc })
end

--- Maps lhs to `:Inspect` (highlight groups under cursor).
---@param lhs?  string Default: "<leader>in"
---@param desc? string Default: ":Inspect highlight groups under cursor"
---@return nil
M.inspect = function(lhs, desc)
    lhs  = lhs or "<leader>in"
    desc = desc or ":Inspect highlight groups under cursor"
    vim.keymap.set({ "n" }, lhs, "<cmd>Inspect<CR>", { desc = desc })
end

--- Maps lhs to re-trigger fold recomputation by re-assigning `foldmethod`
--- to itself.
---@param lhs?  string Default: "<leader>rf"
---@param desc? string Default: "Reload foldmethod"
---@return nil
M.reload_foldmethod = function(lhs, desc)
    lhs  = lhs or "<leader>rf"
    desc = desc or "Reload foldmethod"
    vim.keymap.set({ "n" }, lhs, function()
        vim.o.foldmethod = vim.o.foldmethod
        vim.print("foldmethod=" .. vim.o.foldmethod)
    end, { desc = desc }
    )
end

--- Maps indent/dedent in visual mode to reselect afterward (">gv"/"<gv"),
--- instead of exiting visual mode.
---@param indent? string Default: ">"
---@param dedent? string Default: "<"
---@param desc?   string Default: "Remain in visual mode after indenting"
---@return nil
M.visual_indent_persist = function(indent, dedent, desc)
    indent = indent or ">"
    dedent = dedent or "<"
    desc   = desc or "Remain in visual mode after indenting"
    vim.keymap.set("x", indent, ">gv", { desc = desc })
    vim.keymap.set("x", dedent, "<gv", { desc = desc })
end

--- Maps lhs to native "gF" (goto file, honouring a trailing line number).
---@param lhs?  string Default: "gf"
---@param desc? string Default: "Open file and if provided, go to line
---  number"
---@return nil
M.file_goto = function(lhs, desc)
    lhs  = lhs or "gf"
    desc = desc or "Open file and if provided, go to line number"
    vim.keymap.set({ "n", "x" }, lhs, "gF", { desc = desc })
end

--- Maps lhs to create or open the file under cursor (`:e <cfile>`).
---@param lhs?  string Default: "gF"
---@param desc? string Default: "Create or open new file according to
---  path under cursor"
---@return nil
M.file_create_or_open = function(lhs, desc)
    lhs  = lhs or "gF"
    desc = desc or "Create or open new file according to path under cursor"
    vim.keymap.set({ "n", "x" }, lhs, "<cmd>e <cfile><CR>", { desc = desc })
end

--- Routes single-character deletion ("x") and visual paste-over ("p")
--- through the blackhole register, so they don't clobber the unnamed
--- register.
---@return nil
M.blackhole_register = function()
    vim.keymap.set({ "n" }, "x", '"_x', {
        desc = "Blackhole Register: Single character deletion",
    })
    vim.keymap.set({ "v" }, "p", '"_dP', {
        desc = "Blackhole Register: Pasted over selection",
    })
end

--- Registers every keymap this config defines.
---@return nil
M.setup = function()
    M.clear_hlsearch("<leader>h")
    M.toggle_relativenumber("<leader>rn")
    M.blink_relativenumber("<leader>nn")
    M.blink_linenumber("<leader>ln")
    M.format_buffer("<leader>tw")
    M.inspect("<leader>in")
    M.reload_foldmethod("<leader>rf")

    -- Without arguments, replace native keymaps
    M.visual_indent_persist()
    M.file_goto()
    M.file_create_or_open()
    require("keymap.gx").setup()

    -- Doesn't accept arguments
    M.blackhole_register()
end

return M
