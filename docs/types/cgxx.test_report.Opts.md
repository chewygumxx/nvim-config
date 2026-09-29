# class Opts



- namespace: cgxx.test_report



Options for `M.reporter`.







---



## fields
---

### Opts.xml
---
```lua
Opts.xml : string?
```



JUnit XML path; nil writes none








### Opts.summary
---
```lua
Opts.summary : string?
```



Markdown path appended to; nil none








### Opts.slowest
---
```lua
Opts.slowest : integer?
```



Slow cases to print (default: 10)








### Opts.quit
---
```lua
Opts.quit : boolean?
```



Whether `finish` exits (default: true)








### Opts.delegate
---
```lua
Opts.delegate : mini.test.Reporter?
```



Reporter to wrap (default: stdout's)









