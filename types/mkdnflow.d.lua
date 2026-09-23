#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/types/mkdnflow.lua
--
--

--
-- Local stand-in for jakewvincent/mkdnflow.nvim's own opts type, so
-- lua/spec/mkdnflow.lua still resolves once the plugin is pruned from
-- ~/.local/share/nvim/lazy. mkdnflow.nvim ships no LuaCATS
-- annotations, so this name is invented locally; nested structs mirror
-- lua/spec/mkdnflow.lua's own field set (which itself transcribes the
-- plugin's README) rather than a vendored source. `highlight`/`marker`/
-- `content` sub-tables reuse Neovim's own `vim.api.keyset.highlight`,
-- which is still real and resolvable via `$VIMRUNTIME/lua`.
--

---@meta

---@class (exact) cgxx.spec.mkdnflow.ModulesOpts
---@field buffers?    boolean
---@field cursor?     boolean
---@field links?      boolean
---@field paths?      boolean
---@field yaml?       boolean
---@field tables?     boolean
---@field lists?      boolean
---@field to_do?      boolean
---@field folds?      boolean
---@field maps?       boolean
---@field conceal?    boolean
---@field templates?  boolean
---@field notebook?   boolean
---@field bib?        boolean
---@field backlinks?  boolean
---@field completion? boolean
---@field foldtext?   boolean

---@alias cgxx.spec.mkdnflow.PathResolutionMode "first" | "current" | "root"

---@class (exact) cgxx.spec.mkdnflow.PathResolutionOpts
---@field root_marker?        string
---@field primary?            cgxx.spec.mkdnflow.PathResolutionMode
---@field fallback?           cgxx.spec.mkdnflow.PathResolutionMode
---@field update_on_navigate? boolean
---@field sync_cwd?           boolean

---@class (exact) cgxx.spec.mkdnflow.CursorOpts
---@field jump_patterns? table
---@field yank_register? string

---@alias cgxx.spec.mkdnflow.LinkStyle "markdown" | "wiki"

---@class (exact) cgxx.spec.mkdnflow.LinksOpts
---@field style?               string | cgxx.spec.mkdnflow.LinkStyle
---@field compact?             boolean
---@field conceal?             boolean
---@field ref_hint?            boolean
---@field search_range?        integer
---@field implicit_extension?  boolean
---@field transform_on_follow? boolean | fun(text: string): string
---@field transform_on_create? boolean | fun(text: string): string
---@field transform_scope?     string
---@field auto_create?         boolean
---@field on_create_new?       boolean

---@class (exact) cgxx.spec.mkdnflow.NewFileTemplateOpts
---@field enabled?      boolean
---@field placeholders? table<string, string | fun(): string>
---@field template?     string

---@alias cgxx.spec.mkdnflow.ToDoSortPosition "top" | "bottom"

---@class (exact) cgxx.spec.mkdnflow.ToDoStatusSortOpts
---@field section?  integer
---@field position? cgxx.spec.mkdnflow.ToDoSortPosition

---@class (exact) cgxx.spec.mkdnflow.ToDoItemStatus
---@field name string

---@class (exact) cgxx.spec.mkdnflow.ToDoItem
---@field status cgxx.spec.mkdnflow.ToDoItemStatus

---@class (exact) cgxx.spec.mkdnflow.ToDoList
---@field items cgxx.spec.mkdnflow.ToDoItem[]

---@class (exact) cgxx.spec.mkdnflow.ToDoStatusPropagateOpts
---@field up?   fun(host_list: cgxx.spec.mkdnflow.ToDoList): string
---@field down? fun(child_list: cgxx.spec.mkdnflow.ToDoList): string[]

---@class (exact) cgxx.spec.mkdnflow.ToDoStatusOpts
---@field marker?    string | string[]
---@field highlight? table<"marker" | "content", vim.api.keyset.highlight>
---@field sort?      cgxx.spec.mkdnflow.ToDoStatusSortOpts
---@field propagate? cgxx.spec.mkdnflow.ToDoStatusPropagateOpts

---@class (exact) cgxx.spec.mkdnflow.ToDoSortOpts
---@field on_status_change? boolean
---@field recursive?        boolean
---@field cursor_behavior?  { track?: boolean }

---@class (exact) cgxx.spec.mkdnflow.ToDoOpts
---@field highlight?          boolean
---@field statuses?           table<string, cgxx.spec.mkdnflow.ToDoStatusOpts>
---@field status_order?       string[]
---@field status_propagation? { up?: boolean, down?: boolean }
---@field sort?               cgxx.spec.mkdnflow.ToDoSortOpts

---@class (exact) cgxx.spec.mkdnflow.TableStyleOpts
---@field cell_padding?      integer
---@field separator_padding? integer
---@field outer_pipes?       boolean
---@field apply_alignment?   boolean

---@class (exact) cgxx.spec.mkdnflow.TablesOpts
---@field type?             string
---@field trim_whitespace?  boolean
---@field format_on_move?   boolean
---@field auto_extend_rows? boolean
---@field auto_extend_cols? boolean
---@field style?            cgxx.spec.mkdnflow.TableStyleOpts

---@class (exact) cgxx.spec.mkdnflow.YamlOpts
---@field bib? { override?: boolean }

---@class (exact) cgxx.spec.mkdnflow.MappingSpec
---@field [1] string | string[]
---@field [2] string

---@class (exact) cgxx.spec.mkdnflow.FoldtextFillCharsOpts
---@field left_edge?         string
---@field right_edge?        string
---@field item_separator?    string
---@field section_separator? string
---@field left_inside?       string
---@field right_inside?      string
---@field middle?            string

---@class (exact) cgxx.spec.mkdnflow.FoldtextOpts
---@field object_count?          boolean
---@field object_count_icon_set? string
---@field object_count_opts?     fun(): table
---@field line_count?            boolean
---@field line_percentage?       boolean
---@field word_count?            boolean
---@field title_transformer?     fun(): fun(title: string): string
---@field fill_chars?            cgxx.spec.mkdnflow.FoldtextFillCharsOpts

---@class (exact) cgxx.spec.mkdnflow.BibOpts
---@field default_path? string
---@field find_in_root? boolean

---@class cgxx.spec.mkdnflow.Config
---@field wrap?              boolean
---@field silent?            boolean
---@field on_attach?         boolean | fun(bufnr: integer)
---@field create_dirs?       boolean
---@field modules?           cgxx.spec.mkdnflow.ModulesOpts
---@field path_resolution?   cgxx.spec.mkdnflow.PathResolutionOpts
---@field filetypes?         table<string, boolean | string>
---@field cursor?            cgxx.spec.mkdnflow.CursorOpts
---@field links?             cgxx.spec.mkdnflow.LinksOpts
---@field new_file_template? cgxx.spec.mkdnflow.NewFileTemplateOpts
---@field to_do?             cgxx.spec.mkdnflow.ToDoOpts
---@field tables?            cgxx.spec.mkdnflow.TablesOpts
---@field yaml?              cgxx.spec.mkdnflow.YamlOpts
---@field mappings?          table<string, cgxx.spec.mkdnflow.MappingSpec | false>
---@field foldtext?          cgxx.spec.mkdnflow.FoldtextOpts
---@field bib?               cgxx.spec.mkdnflow.BibOpts
