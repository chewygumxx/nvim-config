local result = vim.system({
    "lua-language-server",
    "--check=" .. vim.fn.getcwd(),
    "--checklevel=Hint",
    "--check_format=pretty",
}, { text = true }):wait()
io.write(result.stdout or "", result.stderr or "")
os.exit(result.code)
