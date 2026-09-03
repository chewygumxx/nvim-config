-- vim: foldlevel=1:foldmethod=expr
-- luacheck: globals vim

--
--
-- ~/.config/nvim/lua/spec/mini.nvim.lua
--
--

--
--  https://github.com/nvim-mini/mini.nvim
--

local M = { 
    'nvim-mini/mini.nvim', 
    enabled = true,
    version = false,  -- 'main' branch
}

local modules = {
    hipatterns = function()
        local hipatterns = require('mini.hipatterns')
        local opts = {
            highlighters = {
                hex_color = hipatterns.gen_highlighter.hex_color({
                    "line", --<style>
                    200,    --<priority>
                    function() return true end,  --<filter>
                    nil,
                }),
            }
        }
        hipatterns.setup(opts)
    end,
    icons = function()
        require('mini.icons').setup()
    end,
    files = function()
        require('mini.files').setup({
            -- Customization of shown content
            content = {
                -- Predicate for which file system entries to show
                filter = nil,
                -- What prefix to show to the left of file system entry
                prefix = nil,
                -- In which order to show file system entries
                sort = nil,
            },
            
            -- Module mappings created only inside explorer.
            -- Use `''` (empty string) to not create one.
            mappings = {
                close       = 'q',
                go_in       = 'L',
                go_in_plus  = '',
                go_out      = 'H',
                go_out_plus = '',
                mark_goto   = "'",
                mark_set    = 'm',
                reset       = '<BS>',
                reveal_cwd  = '@',
                show_help   = 'g?',
                synchronize = '=',
                trim_left   = '<',
                trim_right  = '>',
            },
            
            -- General options
            options = {
                -- Whether to delete permanently or move into module-specific trash
                permanent_delete = true,
                -- Whether to use for editing directories
                use_as_default_explorer = true,
            },
            
            -- Customization of explorer windows
            windows = {
                -- Maximum number of windows to show side by side
                max_number = math.huge,
                -- Whether to show preview of file/directory under cursor
                preview = true,
                -- Width of focused window
                width_focus = 80,
                -- Width of non-focused window
                width_nofocus = 20,
                -- Width of preview window
                width_preview = 30,
            },
        })
    end,
}

M.config = function()
    modules.hipatterns()
  --modules.icons()
  --modules.files()
    
    --for _, setup in pairs(modules) do setup() end
end

return M

