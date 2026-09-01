#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

-- 
-- 
-- ~chewygumxx/dotfiles.git
-- ::: :/home/dot_config/nvim/lua/spec/starry.lua
-- 
-- 

local M = {
    'ray-x/starry.nvim',
    
    lazy     = false,
    priority = 1001,  -- Load this first and foremost
}

M.opts = {
    -- * Options
    -- Referenced/Unpacked at:
    --   - starry/util.lua:2
    --   - starry/util.lua:61
    --   - starry/util.lua:105

    border   = true,  -- Split window borders
    hide_eob = true, -- Hide end of buffer
    
    -- * Syntax Font Styling: Italics
    italics = {
        comments  = false,  -- Italic comments
        strings   = false,  -- Italic strings
        keywords  = false,  -- Italic keywords
        functions = false,  -- Italic functions
        variables = false,  -- Italic variables
    },
    
    -- * Contrast Background per Window/Filetype
    contrast = {
        enable = false,  
        
        -- Terminal Window       [starry/utils.lua:64]
        terminal = false,
        
        -- Darken by Filetype       [starry/utils.lua:72]
        -- e.g. *.vim, *.cpp, etc.
        filetypes = {},  
    },
    
    -- * High Contrast Text
    -- Whether to apply higher contrasting text
    -- Set in accordance with theme variant (_lighter or standard)
    text_contrast = {
        lighter = false,  -- For lighter variant
        darker = true   -- For standard variant
    },
    
    disable = {
        background = true,   -- If true > transparent background
        term_colors = false, -- Disable defining the terminal colors
        eob_lines = false    -- Make end-of-buffer lines invisible
    },
    
    -- * Theme Name
    -- If truthy 
    --  > style.name negated
    -- String values accepted: 
    -- [starry/util.lua:81]
    -- - dark_solar
    -- - darker
    -- - 'deep ocean'
    -- - dracula   
    -- - dracula_blood  
    -- - earlysummer  
    -- - emerald
    -- - mariana
    -- - mariana_lighter
    -- - middlenight_blue
    -- - monokai
    -- - monokai_lighter
    -- - moonlight   
    -- - oceanic   
    -- - palenight 
    -- - ukraine
    theme = false, 
    
    style = {
        -- * Theme Style Name      
        -- [starry/utils.lua:120]
        -- If style.fix is truthy
        -- > style.name negated
        -- If style.fix falsy and name falsy 
        -- > defaults to 'monokai'     [starry/util.lua:118]
        -- String values accepted:
        -- > see :64
        name = 'middlenight_blue', 
        
        -- * Forbidden Font Styles
        -- e.g. {'bold', 'underline'}.
        disable = {},  
        
        -- * Random Theme        [starry/util.lua:114]
        -- If true
        -- > style.name = random item of themes array
        --   > see :64
        fix = false, 
        
        -- * Increase Contrast for Standard Variant
        -- Since text_contrast.darker exists, this must be for backgrounds
        darker_contrast = false, 
        
        -- * Day/Night Style Switching    [starry/util.lua:107]
        -- If true > style.fix must be false
        -- If time of day between 06:00 and 18:00
        --  true > lighter variant
        --  false > standard variant
        daylight_switch = false, 
        
        -- Enable a deeper black background
        deep_black = false, 
    },
    
    --custom_colors = {
    -- variable = '#f797d7',
    --},
    
}

M.config = function(_, opts)
    require('starry').setup(opts)
    vim.cmd( [[ colorscheme starry ]] )
end

return M
