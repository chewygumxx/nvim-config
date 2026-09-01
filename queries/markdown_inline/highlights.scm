; vim: expandtab:shiftwidth=4:filetype=query:

; 
; 
; ~chewygumxx/dotfiles.git
; ::: :/dot_config/nvim/queries/markdown_inline/highlights.scm
; 
; 

; 
; Treesitter query, our favourite x-x
; 

(full_reference_link      [ "[" "]" "(" ")" ] @markup.link.bracket)
(collapsed_reference_link [ "[" "]" "(" ")" ] @markup.link.bracket)
(inline_link              [ "[" "]" "(" ")" ] @markup.link.bracket)
(link_label               [ "[" "]" "(" ")" ] @markup.link.bracket)
(shortcut_link            [ "[" "]" "(" ")" ] @markup.link.bracket)
(image                    [ "[" "]" "(" ")" ] @markup.link.bracket)
(link_destination         [ "<" ">" ]        @markup.link.bracket )


(link_text)  @markup.link.text
(link_title) @markup.link.title
[
  (link_label)
  (image_description)
] @markup.link.label




;
; From tree-sitter-grammars/tree-sitter-markdown
; (removed @markup.link)
;

; From MDeiml/tree-sitter-markdown
(code_span) @markup.raw @nospell

(emphasis) @markup.italic

(strong_emphasis) @markup.strong

(strikethrough) @markup.strikethrough

(shortcut_link
  (link_text) @nospell)

; Conceal backslash in backslash escapes
((backslash_escape) @conceal
  (#offset! @conceal 0 0 0 -1)
  (#set! conceal ""))

; Conceal backslash in hard line breaks
((hard_line_break
  "\\" @conceal)
  (#set! conceal ""))

; Conceal codeblock and text style markers
([
  (code_span_delimiter)
  (emphasis_delimiter)
] @conceal
  (#set! conceal ""))

; Conceal inline links
(inline_link
  [
    "["
    "]"
    "("
    (link_destination)
    ")"
  ]
  (#set! conceal ""))


; Conceal image links
(image
  [
    "!"
    "["
    "]"
    "("
    (link_destination)
    ")"
  ] 
  (#set! conceal ""))

; Conceal full reference links
(full_reference_link
  [
    "["
    "]"
    (link_label)
  ]
  (#set! conceal ""))

; Conceal collapsed reference links
(collapsed_reference_link
  [
    "["
    "]"
  ]
  (#set! conceal ""))

; Conceal shortcut links
(shortcut_link
  [
    "["
    "]"
  ]
  (#set! conceal ""))

[
  (link_destination)
  (uri_autolink)
  (email_autolink)
] @markup.link.url @nospell

((uri_autolink) @_url
  (#offset! @_url 0 1 0 -1)
  (#set! @_url url @_url))

(entity_reference) @nospell

; Replace common HTML entities.
((entity_reference) @character.special
  (#eq? @character.special "&nbsp;")
  (#set! conceal " "))

((entity_reference) @character.special
  (#eq? @character.special "&lt;")
  (#set! conceal "<"))

((entity_reference) @character.special
  (#eq? @character.special "&gt;")
  (#set! conceal ">"))

((entity_reference) @character.special
  (#eq? @character.special "&amp;")
  (#set! conceal "&"))

((entity_reference) @character.special
  (#eq? @character.special "&quot;")
  (#set! conceal "\""))

((entity_reference) @character.special
  (#any-of? @character.special "&ensp;" "&emsp;")
  (#set! conceal " "))
