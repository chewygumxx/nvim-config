#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/filetype/gitcommit.lua
--
--

--
-- Filetype settings for the buffers git opens in an editor: a commit
-- message and an interactive rebase todo list.
--
-- The Conventional Commit segments are coloured a part at a time, and
-- nothing here parses them. `tree-sitter-gitcommit` already does, and both
-- its parser and `git_rebase`'s are in `lua/spec/nvim-treesitter.lua`'s
-- `ensure_installed`, so the grammar hands over `(prefix (type))`,
-- `(prefix (scope))`, the surrounding punctuation, the `!` breaking marker,
-- `(subject)` and `(trailer (token))` as captures. This module is therefore
-- a table of highlight links, which `lua/filetype/init.lua` applies once
-- per session.
--
-- The 50 character cap `.commitlintrc.mts` enforces on the whole
-- `type(scope): Subject` header is shown by 'colorcolumn' and deliberately
-- not by the bundled syntax's `gitcommitOverflow` group, which covers
-- exactly this. That group cannot be seen here: `vim.treesitter.start`
-- draws at a higher priority than Vim syntax, and the grammar captures the
-- whole `(subject)` node, overflow included. A guide column is honest about
-- being a guide, and it works the same in the rebase buffer.
--
-- Routed from both `gitcommit` and `gitrebase`, so `spell` is carried over
-- from `filetype.prose` rather than inherited: the dispatcher runs exactly
-- one module per filetype.
--

local M = {}

---@type { [string]: number | string | boolean }
M.local_opts = {
    spell = true,

    -- git's own conventions: a body wrapped at 72, and `#` comments. The
    -- second guide is the subject cap, one past the last column a header
    -- may occupy, so a header that reaches it has already failed
    -- commitlint.
    textwidth     = 72,
    colorcolumn   = "51,73",
    commentstring = "# %s",
}

---@type { [string]: vim.api.keyset.highlight }
M.hlgroup_defs = {
    -- `type(scope): Subject`, left to right. The type is the part a reader
    -- scans for, the scope narrows it, and the punctuation is structure
    -- rather than content, so it recedes.
    ["@keyword.gitcommit"]               = { fg = "#8874ed", bold = true },
    ["@variable.parameter.gitcommit"]    = { fg = "#7fb5ff" },
    ["@punctuation.delimiter.gitcommit"] = { fg = "#4408a4" },
    ["@markup.heading.gitcommit"]        = { fg = "#cad6ff", bold = true },

    -- A `!` before the colon and a `BREAKING CHANGE:` trailer say the same
    -- thing, so they are given the same weight, and borrowed from the
    -- diagnostic palette rather than invented: this is the one part of a
    -- commit message that should read as a warning.
    ["@punctuation.special.gitcommit"] = { link = "DiagnosticError" },
    ["@comment.error.gitcommit"]       = { link = "DiagnosticError" },

    -- Trailers (`Signed-off-by:`, `Co-Authored-By:`) and the branch named
    -- in git's own generated comment
    ["@label.gitcommit"]       = { fg = "#aaa6fa" },
    ["@markup.link.gitcommit"] = { fg = "#7fb5ff", underline = true },

    -- The rebase todo list: one command per line, with the commit it acts
    -- on. `git_rebase` captures the command as `@keyword` and the hash as
    -- `@constant`.
    ["@keyword.git_rebase"]  = { fg = "#8874ed", bold = true },
    ["@constant.git_rebase"] = { fg = "#6f25f6" },
    ["@operator.git_rebase"] = { fg = "#4408a4" },
}

return M
