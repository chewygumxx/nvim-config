#!/bin/false
-- vim: expandtab:shiftwidth=4

--
--
-- ~/.config/nvim/lua/spec/mkdnflow.lua
--
--

---@module "lazy"
---@type LazySpec
local M = {
    -- https://github.com/jakewvincent/mkdnflow.nvim/blob/main/README.md
    url = 'https://github.com/jakewvincent/mkdnflow.nvim',
    enabled = false,

    -- Populated by function 'filetype_triggers' (defined within file)
    ft  = {},
}

M.opts = {
    -- Wrap to file beginning/end when traversing links/headings,
    -- https://github.com/jakewvincent/mkdnflow.nvim/blob/main/README.md#wrap
    wrap = false,

    -- Limit plugin `:messages` to configuration error
    -- https://github.com/jakewvincent/mkdnflow.nvim/blob/main/README.md#silent
    silent = false,


    on_attach = false,

    -- If true, create non-existent directories upon new-file link follow
    -- (ensure link reference spelling).
    -- If false, following new-file links will create a new buffer assigned to
    -- the non-existent directory and Neovim will fail to write to it.
    -- https://github.com/jakewvincent/mkdnflow.nvim/blob/main/README.md#create_dirs
    create_dirs = true,
}

M.opts.modules = {
    -- https://github.com/jakewvincent/mkdnflow.nvim/blob/main/README.md#modules

    -- Core
    -- Setting false only disables keybinds
    buffers    = true,
    cursor     = true,
    links      = true,
    paths      = true,

    -- Auxillary
    yaml       = true,   -- Yaml headers
    tables     = true,   -- Table management, formatting and navigation.
    lists      = true,   -- List work and manipulation
    to_do      = true,   -- Todo manipulation of state and collation
    folds      = true,   -- Section folding

    -- Luxury
    maps       = true,   -- Keybinds
    conceal    = false,  -- Link concealing (see links.conceal)
    templates  = false,  -- New-file formatting and injection when following links

    -- Cross-file primitives for scanning nb files, heading, links
    --
    -- Rationale: I want this to plugin for general markdown use. Not limited
    -- to my personal notebook repositories.
    notebook   = false,

    -- Expendable
    bib        = false,  -- Follow citations and bib file parse
    backlinks  = false,  -- Side panel showing notebook files referencing current file
    completion = false,  -- For completion plugins such as nvim-cmp and blink.cmp
    foldtext   = false,  -- Adorns foldtext with fold metadata infomation
}

M.opts.path_resolution = {
    -- https://github.com/jakewvincent/mkdnflow.nvim/blob/main/README.md#path_resolution

    root_marker = ".nex_root",  -- Filename by which notebook root directory resolvable

    -- Resolve paths relative to the:
    -- - 'first'   -> First file opened by current Neovim instance (default)
    -- - 'current' -> Currently viewed file
    -- - 'root'    -> Notebook root directory
    primary     = "current",
    fallback    = "root",

    update_on_navigate = true,  -- Recalibrate path resolution heuristic upon notebook/wiki change

    -- Synchronise curent working directory to currently viewed file.
    -- Instrumental when referencing assets relative to the current file
    -- especially synergises with path-supporting completion plugins.
    sync_cwd    = true,
}

M.opts.filetypes = {
    -- https://github.com/jakewvincent/mkdnflow.nvim/blob/main/README.md#filetypes

    -- If this plugin is lazy-loaded per defined filetype (ie. ft = { "markdown" }),
    -- all filetypes within this Lua table configured to be served by this plugin
    -- should also be defined/listed as plugin-load filetype triggers.
    -- (eg. ft = { "markdown", "rmd", "wiki" })

    markdown = true,
    --rmd    = true, -- R Markdown

    --wiki   = true,       -- Resolve *.wiki as filetype 'wiki'
    --txt    = "markdown", -- Resolve *.txt  as filetype 'markdown'
    --html   = false,      -- Disable *.html resolution for this plugin
}
local filetype_triggers = function ()
    for filetype, value in pairs(M.opts.filetypes) do
        if (value ~= false) then -- 'value' may be boolean or string
            table.insert(M.ft, filetype)
        end
    end
end
filetype_triggers()

M.opts.cursor = {
    -- https://github.com/jakewvincent/mkdnflow.nvim/blob/main/README.md#cursor

    -- Table of Lua regex patterns as jump destinations in addition to
    -- detection-based followLink() as per `links.style` (ignores links within
    -- code blocks and spans).
    jump_patterns = nil,

    -- Yank anchor links to this register
    yank_register = "a",
}

M.opts.links = {
    -- https://github.com/jakewvincent/mkdnflow.nvim/blob/main/README.md#links

    style   = 'markdown', -- 'markdown' or 'wiki' link format: []() or [[|]]
    compact = false,      -- Wiki-link: [[source]] or [[source|name]]
    conceal = true,       -- Conceal reference content of link

    -- Show link metadata as virtual text (highlight group: 'MkdnflowRefHint').
    -- For:
    -- - Reference-style links: Resolved URL
    -- - Reference definitions: Usage count
    ref_hint = true,

    -- Search lines surrounding link for further link reference data
    search_range = 0,

    -- Implied link reference file extension if none specified
    implicit_extension = false,

    -- Function to transform name text into source path
    transform_on_follow = false,
    transform_on_create = false,
    --transform_on_create = function(text)
    --    text = text:gsub('[ /]', '-')
    --    text = text:lower()
    --    text = os.date('%Y-%m-%d_') .. text
    --    return text
    --end,

    transform_scope = 'path',
    auto_create = true,
    on_create_new = false,
}

M.opts.new_file_template = {
    enabled      = false,
    placeholders = {},
    template     = '# {{ title }}',
}

M.opts.to_do = {
    highlight = false,
    statuses = {
        not_started = {
            marker = ' ',
            highlight = {
                marker  = { link = 'Conceal' },
                content = { link = 'Conceal' },
            },
            sort = { section = 2, position = 'top' },
            propagate = {
                up = function(host_list)
                    local no_items_started = true
                    for _, item in ipairs(host_list.items) do
                        if item.status.name ~= 'not_started' then
                            no_items_started = false
                        end
                    end
                    if no_items_started then
                        return 'not_started'
                    else
                        return 'in_progress'
                    end
                end,
                down = function(child_list)
                    local target_statuses = {}
                    for _ = 1, #child_list.items, 1 do
                        table.insert(target_statuses, 'not_started')
                    end
                    return target_statuses
                end,
            },
        },
        in_progress = {
            marker = '-',
            highlight = {
                marker = { link = 'WarningMsg' },
                content = { bold = true },
            },
            sort = { section = 1, position = 'bottom' },
            propagate = {
                up   = function(host_list)
                    return 'in_progress'
                end,
                down = function(child_list)
                end,
            },
        },
        complete = {
            marker = { 'X', 'x' },
            highlight = {
                marker = { link = 'String' },
                content = { link = 'Conceal' },
            },
            sort = { section = 3, position = 'top' },
            propagate = {
                up = function(host_list)
                    local all_items_complete = true
                    for _, item in ipairs(host_list.items) do
                        if item.status.name ~= 'complete' then
                            all_items_complete = false
                        end
                    end
                    if all_items_complete then
                        return 'complete'
                    else
                        return 'in_progress'
                    end
                end,
                down = function(child_list)
                    local target_statuses = {}
                    for _ = 1, #child_list.items, 1 do
                        table.insert(target_statuses, 'complete')
                    end
                    return target_statuses
                end,
            },
        },
    },
    status_order = { 'not_started', 'in_progress', 'complete' },
    status_propagation = {
        up = true,
        down = true,
    },
    sort = {
        on_status_change = false,
        recursive = false,
        cursor_behavior = { track = true, },
    },
}

M.opts.tables = {
    type = 'pipe',
    trim_whitespace  = true,
    format_on_move   = true,
    auto_extend_rows = false,
    auto_extend_cols = false,
    style = {
        cell_padding      = 1,
        separator_padding = 1,
        outer_pipes       = true,
        apply_alignment   = true,
    },
}

M.opts.yaml = { bib = { override = false }, }

M.opts.mappings = {
    MkdnEnter      = { { 'n', 'v' }, '<CR>' },
    MkdnGoBack     = { 'n', '<BS>' },
    MkdnGoForward  = { 'n', '<Del>' },
    MkdnMoveSource = { 'n', '<F2>' },
    MkdnNextLink = { 'n', '<Tab>' },
    MkdnPrevLink = { 'n', '<S-Tab>' },
    MkdnFollowLink = false,
    MkdnDestroyLink = { 'n', '<M-CR>' },
    MkdnTagSpan = { 'v', '<M-CR>' },
    MkdnYankAnchorLink = { 'n', 'yaa' },
    MkdnYankFileAnchorLink = { 'n', 'yfa' },
    MkdnNextHeading = { 'n', ']]' },
    MkdnPrevHeading = { 'n', '[[' },
    MkdnNextHeadingSame = { 'n', '][' },
    MkdnPrevHeadingSame = { 'n', '[]' },

    MkdnIncreaseHeading = { { 'n', 'v' }, '+' },
    MkdnDecreaseHeading = { { 'n', 'v' }, '-' },
    MkdnIncreaseHeadingOp = { { 'n', 'v' }, 'g+' },
    MkdnDecreaseHeadingOp = { { 'n', 'v' }, 'g-' },
    MkdnToggleToDo = { { 'n', 'v' }, '<C-Space>' },
    MkdnNewListItem = false,
    MkdnNewListItemBelowInsert = { 'n', 'o' },
    MkdnNewListItemAboveInsert = { 'n', 'O' },
    MkdnExtendList = false,
    MkdnUpdateNumbering = { 'n', '<leader>nn' },

    MkdnTableNextCell = { 'i', '<Tab>' },
    MkdnTablePrevCell = { 'i', '<S-Tab>' },
    MkdnTableNextRow = false,
    MkdnTablePrevRow = { 'i', '<M-CR>' },
    MkdnTableNewRowBelow = { 'n', '<leader>ir' },
    MkdnTableNewRowAbove = { 'n', '<leader>iR' },
    MkdnTableNewColAfter = { 'n', '<leader>ic' },
    MkdnTableNewColBefore = { 'n', '<leader>iC' },
    MkdnTableDeleteRow = { 'n', '<leader>dr' },
    MkdnTableDeleteCol = { 'n', '<leader>dc' },

    MkdnFoldSection =      { 'n', '<leader>f' },
    MkdnUnfoldSection = { 'n', '<leader>F' },

    MkdnTab = false,
    MkdnSTab = false,
    MkdnIndentListItem = { 'i', '<C-t>' },
    MkdnDedentListItem = { 'i', '<C-d>' },
    MkdnCreateLink = false,
    MkdnCreateLinkFromClipboard = { { 'n', 'v' }, '<leader>p' },
}

-- Disabled
M.opts.foldtext = {
    object_count = true,
    object_count_icon_set = 'emoji',
    object_count_opts = function()
        return require('mkdnflow').foldtext.default_count_opts()
    end,

    line_count = true,
    line_percentage = true,
    word_count = false,
    title_transformer = function()
        return require('mkdnflow').foldtext.default_title_transformer
    end,

    fill_chars = {
        left_edge = '⢾⣿⣿',
        right_edge = '⣿⣿⡷',
        item_separator = ' · ',
        section_separator = ' ⣹⣿⣏ ',
        left_inside = ' ⣹',
        right_inside = '⣏ ',
        middle = '⣿',
    },
}
M.opts.bib = {
    -- https://github.com/jakewvincent/mkdnflow.nvim/blob/main/README.md#bib

    -- Filepath of default .bib for citation key resolution.
    -- May be external to notebook directory tree.
    default_path = nil,

    -- If both:
    -- -> `path_resolution.primary` is set to "root", and
    -- -> notebook root directory has been resolved
    -- then:
    -- -> Search top-level root directory for referenceable *.bib files.
    --
    -- If `bib.default_path` also resolves to a .bib file, it will also be
    -- referenced for citation key resolution.
    find_in_root = true, 
}

return M
