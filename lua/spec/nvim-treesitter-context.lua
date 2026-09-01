-- vim:

--
--
-- ~/.config/nvim/lua/spec/nvim-treesitter-context.lua
--
--

local M = {
    'nvim-treesitter/nvim-treesitter-context',
    enabled = false,


    opts = {
        mode         = 'cursor',    -- Line used to resolve context. ('cursor', 'topline')
        max_lines    = 0,           -- Maximum window lines. 0 = no limit.
        line_numbers = true,
        multiwindow  = false,       -- Enable multiwindow support.
        trim_scope   = 'outer',     -- Which context lines to discard if `max_lines` exceeded. ('inner', 'outer')
        min_window_height   = 30,   -- Minimum editor window height to enable context. 0 = no limit.
        multiline_threshold = 10,   -- Maximum number of lines to show for a single context

        -- Separator between context and content. Should be a single character string, like '-'.
        -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
        separator = nil,
        zindex    = 20,  -- The Z-index of the context window
        on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
    },
}

return M
