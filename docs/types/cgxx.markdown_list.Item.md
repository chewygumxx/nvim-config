# class Item



- namespace: cgxx.markdown_list



One parsed Markdown list item.







---



## fields
---

### Item.indent
---
```lua
Item.indent : string
```



Leading whitespace, reproduced verbatim








### Item.marker
---
```lua
Item.marker : string
```



The marker as written, eg. `-`, `1`, `>`








### Item.delim
---
```lua
Item.delim : string
```



`.` or `)` for an ordered item, otherwise ""








### Item.spacing
---
```lua
Item.spacing : string
```



Whitespace between the marker and the content








### Item.kind
---
```lua
Item.kind : ("bullet"|"ordered"|"quote")
```










### Item.checkbox
---
```lua
Item.checkbox : string?
```



`" "`, `"x"` or `"X"` when the item has one








### Item.content
---
```lua
Item.content : string
```



Everything after the marker and any checkbox









