; vim:set expandtab shiftwidth=4 filetype=query:
; SPDX-License-Identifier: GPL-3.0-only

; 
; 
; ~chewygumxx/dotfiles.git
; ::: :/home/dot_config/nvim/queries/comment/highlights.scm
; 
; 

;
; Tree-sitter query for https://github.com/stsewd/tree-sitter-comment
;

; Header

; ~chewygumxx/dotfiles.git
(
    "text" @comment.header.repo.owner
    "text" @comment.header.repo.solidus
    "text" @comment.header.repo.name
    "text" @comment.header.repo.dot
    "text" @comment.header.repo.ext
    (#lua-match? @comment.header.repo.owner   "^~[%w_]+$")
    (#eq?        @comment.header.repo.solidus "/")
    (#lua-match? @comment.header.repo.name    "^[%w_]+$")
    (#eq?        @comment.header.repo.dot     ".")
    (#eq?        @comment.header.repo.ext     "git")
    (#adjacent?  @comment.header.repo.owner
                 @comment.header.repo.solidus
                 @comment.header.repo.name
                 @comment.header.repo.dot 
                 @comment.header.repo.ext)
 )

; ::: :/dot_config/nvim/queries/comment/highlights.scm
(
    "text" @comment.header.path.prepend
    "text" @comment.header.path.prepend
    "text" @comment.header.path.prepend
    "text" @comment.header.path.start
    "text" @comment.header.path.start
    "text" @comment.header.path.root_dir
    (#eq?            @comment.header.path.prepend  ":")
    (#lua-match?     @comment.header.path.start    "^[:/]$")
    (#lua-match?     @comment.header.path.root_dir "^[%w_]+$")
    (#adjacent?      @comment.header.path.prepend
                     @comment.header.path.start
                     @comment.header.path.root_dir)
 )
(
    "text" @comment.header.path.sep
    (#any-of?        @comment.header.path.sep      "/")
    (#header-line?   @comment.header.path.sep)
 )
(
    "text" @comment.header.path.subdir
    (#lua-match?     @comment.header.path.subdir   "^[%w_]+$")
    (#header-line?   @comment.header.path.subdir)
 )
(
    "text" @comment.header.path.base
    "text" @comment.header.path.dot
    "text" @comment.header.path.ext
    (#lua-match?     @comment.header.path.base     "^[%w_]+$")
    (#header-line?   @comment.header.path.base     "path")
    (#eq?            @comment.header.path.dot      ".")
    (#lua-match?     @comment.header.path.ext      "^[%w_]+$")
    (#last-matching? @comment.header.path.ext      "^[%w_]+$")
    (#adjacent?      @comment.header.path.base
                     @comment.header.path.dot
                     @comment.header.path.ext)
 )

; From https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/comment/highlights.scm

; TODO(@chewygumxx): Yeet
((tag
   (name) @comment.todo @nospell
   ("(" @punctuation.bracket
    (user) @constant
    ")" @punctuation.bracket)?
   ":" @punctuation.delimiter)
 (#any-of? @comment.todo "TODO" "WIP"))

; TODO
("text" @comment.todo @nospell
 (#any-of? @comment.todo "TODO" "WIP"))

; NOTE(@chewygumxx): Yeet
((tag
   (name) @comment.note @nospell
   ("(" @punctuation.bracket
    (user) @constant
    ")" @punctuation.bracket)?
   ":" @punctuation.delimiter)
 (#any-of? @comment.note "NOTE" "XXX" "INFO" "DOCS" "PERF" "TEST"))

; NOTE
("text" @comment.note @nospell
 (#any-of? @comment.note "NOTE" "XXX" "INFO" "DOCS" "PERF" "TEST"))

; HACK(@chewygumxx): Yeet
((tag
   (name) @comment.warning @nospell
   ("(" @punctuation.bracket
    (user) @constant
    ")" @punctuation.bracket)?
   ":" @punctuation.delimiter)
 (#any-of? @comment.warning "HACK" "WARNING" "WARN" "FIX"))

; HACK
("text" @comment.warning @nospell
 (#any-of? @comment.warning "HACK" "WARNING" "WARN" "FIX"))

; FIXME(@chewygumxx): Yeet
((tag
   (name) @comment.error @nospell
   ("(" @punctuation.bracket
    (user) @constant
    ")" @punctuation.bracket)?
   ":" @punctuation.delimiter)
 (#any-of? @comment.error "FIXME" "BUG" "ERROR"))

; FIXME
("text" @comment.error @nospell
 (#any-of? @comment.error "FIXME" "BUG" "ERROR"))

; Issue number (#123)
("text" @number
 (#lua-match? @number "^#[0-9]+$"))

; https://github.com
(uri) @string.special.url @nospell
