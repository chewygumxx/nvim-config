# class Timed



- namespace: cgxx.test_report



One executed case, flattened to what the renderers below take.







---



## fields
---

### Timed.file
---
```lua
Timed.file : string
```



Test file the case was collected from








### Timed.name
---
```lua
Timed.name : string
```



Its `describe`/`it` descriptions, joined








### Timed.ms
---
```lua
Timed.ms : number
```



Wall time in milliseconds








### Timed.fails
---
```lua
Timed.fails : string[]
```



Assertion failures; empty when the case passed








### Timed.notes
---
```lua
Timed.notes : string[]
```



`MiniTest.add_note` messages









