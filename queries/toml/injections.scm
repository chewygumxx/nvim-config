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
; Multiline scripts with /usr/bin/env <language> shebangs.
(pair
  (bare_key) @_key
  (string) @injection.content @injection.language
  (#eq? @_key "run")
  (#is-mise?)
  (#match? @injection.language "^['\"]{3}\n*#!(/\\w+)+/env\\s+\\w+")
  (#gsub! @injection.language "^['\"]['\"]['\"]\n*#!/[^%s]+/env%s+([^%s]+).*" "%1")
  (#offset! @injection.content 0 3 0 -3))

; Multiline scripts with direct interpreter paths.
(pair
  (bare_key) @_key
  (string) @injection.content @injection.language
  (#eq? @_key "run")
  (#is-mise?)
  (#match? @injection.language "^['\"]{3}\n*#!(/\\w+)+\\s*\n")
  (#gsub! @injection.language "^['\"]['\"]['\"]\n*#!/[^%s]*/([^/%s]+)%s*\n.*" "%1")
  (#offset! @injection.content 0 3 0 -3))

; Bash is the highlighting default for scripts without a shebang.
(pair
  (bare_key) @_key
  (string) @injection.content
  (#eq? @_key "run")
  (#is-mise?)
  (#match? @injection.content "^['\"]{3}")
  (#not-match? @injection.content "^['\"]{3}\n*#!")
  (#offset! @injection.content 0 3 0 -3)
  (#set! injection.language "bash"))

(pair
  (bare_key) @_key
  (string) @injection.content
  (#eq? @_key "run")
  (#is-mise?)
  (#not-match? @injection.content "^['\"]{3}")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.language "bash"))
