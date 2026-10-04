// vim:set expandtab shiftwidth=4 filetype=typescript:
// SPDX-License-Identifier: GPL-3.0-only

//
//
// ~chewygumxx/nvim-config.git
// ::: :/.commitlintrc.mts
//
//

import { defineConfig } from "@chewygumxx/commitlint-config";

// Types, limits and the prompt are shared; only the scopes are this
// repository's own.
export default defineConfig({
    scopes: [
        {
            name: "hl",
            fullName: "Highlight",
            description: "Highlight and colourscheme configuration",
        },
        {
            name: "opt",
            fullName: "Option",
            description: "Neovim option configuration",
        },
        {
            name: "ft",
            fullName: "Filetype",
            description: "Neovim filetype handling",
        },
        {
            name: "key",
            fullName: "Keymap",
            description: "Neovim keymap setup",
        },
        {
            name: "ucmd",
            fullName: "Usercmd",
            description: "Neovim user command definition",
        },
        {
            name: "acmd",
            fullName: "Autocmd",
            description: "Neovim auto command specification",
        },
        {
            name: "lsp",
            fullName: "LSP",
            description: "Language Server Protocol",
        },
        {
            name: "spec",
            fullName: "Spec",
            description: "Plugin load, specification, and integration",
        },
        {
            name: "util",
            fullName: "Utility",
            description: "Composition of utilities beyond plugin specification",
        },
        {
            name: "asset",
            fullName: "Asset",
            description:
                "Inclusion of assets ie. templates, snippets, spell, etc.",
        },
        {
            name: "claude",
            fullName: "Claude",
            description: "Claude Code assets ie. hooks, skills, agents, etc.",
        },
    ],
});
