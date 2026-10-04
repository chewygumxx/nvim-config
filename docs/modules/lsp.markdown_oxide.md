# global lsp.markdown_oxide


A `root_dir` rather than `root_markers`: the server panics on a buffer
with no name, and that buffer would share, and so kill, the cwd's client.
See `util.lsp.named_root`.







---



