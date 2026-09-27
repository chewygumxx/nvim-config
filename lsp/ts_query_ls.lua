#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lsp/ts_query_ls.lua
--
--

--
-- Deliberately empty, and not a placeholder. `nvim-lspconfig` already ships
-- a complete `lsp/ts_query_ls.lua`, and every value in it is the one this
-- repository wants: `filetypes = { "query" }`, which is what Neovim already
-- resolves a `.scm` file under a `queries/` directory to; `root_markers`
-- naming `.tsqueryrc.json`, which exists here for the `Queries` CI job and
-- so anchors the workspace at the repository root; and
-- `vim.g.query_lint_on = {}`, which switches off Neovim's own built-in query
-- linter so its diagnostics do not arrive twice.
--
-- The file has to exist even so. `tests/test_spec.lua` asserts that
-- `lua/spec/mason-lspconfig.nvim.lua`'s `ensure_installed` holds exactly the
-- servers this directory configures, so adding the server there without a
-- file here fails the suite.
--

---@type vim.lsp.Config
local M = {}

return M
