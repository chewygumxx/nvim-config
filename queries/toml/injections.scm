; extends

; vim:set expandtab shiftwidth=2 filetype=query:
; SPDX-License-Identifier: GPL-3.0-only
;
;
; ~chewygumxx/nvim-config.git
; ::: :/queries/toml/injections.scm
;
;
; Based on https://mise.jdx.dev/mise-cookbook/neovim.html
; Multiline scripts take the language their shebang names, through `env` or
; a direct path, and default to Bash. See util.treesitter.shebang_lang.
(pair
  (bare_key) @_key
  (string) @injection.content
  (#eq? @_key "run")
  (#is-mise?)
  (#match? @injection.content "^['\"]{3}")
  (#offset! @injection.content 0 3 0 -3)
  (#set-lang-from-shebang! @injection.content "bash"))

; Single-line scripts have no room for a shebang.
(pair
  (bare_key) @_key
  (string) @injection.content
  (#eq? @_key "run")
  (#is-mise?)
  (#not-match? @injection.content "^['\"]{3}")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.language "bash"))
