-- vim:foldlevel=1:foldmethod=expr

--
--
-- ~/.config/nvim/lua/spec/neorg.lua
--
--

local M = {
    "nvim-neorg/neorg",
    name = "Neorg",
    dev  = false,
    enabled = false,
    opts = {},
} 

-- Neorg Modules
M.opts.load = {
    ["core.defaults"] = {},
    ["core.esupports.indent"] = {
        config = {
            dedent_excess = false,
            format_on_enter = false,
            format_on_escape = false,

            indents = {
                paragraph_segment = {
                    indent = 4,
                    modifiers = {
                        "under-headings",
                        "under-nestable-detached-modifiers"
                    }
                }
            }
        }
    },
    ["core.esupports.hop"] = {},
    ["core.todo-introspector"] = {
        config = {
            highlight_group = "String",
            
            ---@param completed number Total number of completed tasks
            ---@param total  number Total number of tasks
            format = function(completed, total)
                return string.format(
                    "[%d/%d] [%d%%]",
                    completed,
                    total,
                    (total ~= 0 and math.floor((completed / total) * 100) or 0)
                )
            end
        }
    },
    ["core.dirman"] = {
        config = {
            default_workspace = "neorg",
            open_last_workspace = "default",
            workspaces = { neorg = "~/note/neorg" },
        }
    },
    ["core.concealer"] = {
        config = {
            folds = true,
            icon_preset = "diamond"
        }
    },
    ["core.summary"] = {}
}

--vim.api.nvim_set_keymap("n", "<CR>", "<Plug>(neorg.esupports.hop.hop-link)",
--    { desc = "Follow Neorg-based link to referenced file" }
--)

return M
