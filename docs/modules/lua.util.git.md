# global lua.util.git








---

## methods
---

### M.slug
---
```lua
function M.slug(
  file: string?,
  remote: string?
) -> slug string?
```
@param `file` - File to resolve from (default: current buffer)

@param `remote` - Remote name (default: "origin")


@return `slug` - "owner/repo", or nil if file has no such remote





Resolves the "owner/repo" slug of file's git remote.








### M.license
---
```lua
function M.license(slug: string) -> spdx_id string?
```
@param `slug` - owner/repo


@return `spdx_id` - SPDX identifier, or nil on lookup failure





Resolves slug's SPDX license identifier via the GitHub API.








### M.path
---
```lua
function M.path(file: string?) -> path string
```
@param `file` - File to resolve from (default: current buffer)


@return `path` - ":"-prefixed root-relative path, or a "~"-relative
  path if file isn't inside a git repository





Resolves file's path relative to its git repository root.








### M.branch
---
```lua
function M.branch(file: string?) -> branch string?
```
@param `file` - File to resolve from (default: current buffer)


@return `branch` - Branch name, or nil if file's repository has a
  detached HEAD, or file isn't inside a git repository





Resolves the branch checked out by file's git repository.








### M.info
---
```lua
function M.info(
  file: string?,
  callback: fun(info: cgxx.git.info?)
) ->  nil
```
@param `file` - Default: current buffer

@param `callback` - Receives nil if file isn't
  inside a git repository, or if git fails or times out. Always called
  outside a fast event, so it may touch buffers and options.






Everything `M.path`, `M.branch` and `M.slug` answer separately, in one
process and without blocking.

The sync trio costs three spawns, which is fine once for a header or a
user command but not on a path that runs per buffer displayed: three
`:wait()` calls stall the UI for as long as git takes, multiplied by
every buffer in a sweep. One `sh -c` collapses that to a single
non-blocking spawn, the same trade `util.wip` makes for its snapshots.

Deliberately reports a detached HEAD as an empty branch rather than an
abbreviated SHA, leaving the substitution to the caller.








### M.gh
---
```lua
function M.gh(
  slug: string,
  opts: cgxx.git.gh.opts {
    fmt = cgxx.git.gh.opts.fmt,
}
) -> url string
```
@param `slug` - owner/repo

@param `opts` - Additional options ie. fmt = "ssh"|"https"


@return `url` - Repository GitHub URL





Returns the repository GitHub URL of the provided slug











