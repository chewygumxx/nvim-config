# global lua.util.text








---

## methods
---

### M.yaml_scalar
---
```lua
function M.yaml_scalar(text: string) -> scalar string
```





Renders text as a YAML flow scalar, double-quoting it only when a
plain scalar would be ambiguous or invalid.

Lives here rather than beside either caller: `util.header.frontmatter`
and `util.nex` both write `title:` and tag keys, and a second copy of
this would be a second opinion on what YAML needs quoting.








### M.wrap_comment
---
```lua
function M.wrap_comment(
  text: string,
  width: integer?,
  opt: util.WrapCommentOpt?
) -> lines string[]
```
@param `width` - Default: 'textwidth', or 80 if unset






Wraps text into a list of comment lines no wider than width, each
formatted through commentstring.











