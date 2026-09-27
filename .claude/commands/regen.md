---
description: >-
  Regenerate doc/ and docs/ and verify both trees are clean
---

Regenerate this repository's two generated trees. Invoke the `generated-output`
skill first for why each step is shaped the way it is.

Never hand-edit anything under `doc/` or `docs/`. Both generators delete the
whole tree and recreate it, so an edit there vanishes silently;
`.claude/hooks/block-generated.sh` refuses the write.

```sh
. ./.claude/hooks/lib/tools.sh && mise_path
nvim --headless -u scripts/minimal_init.lua -l scripts/genhelp.lua
nvim --headless -u scripts/minimal_init.lua -l scripts/gendoc.lua
```

Both run through Neovim so the child inherits `$VIMRUNTIME`, which
`.luarc.json`'s `workspace.library` needs. From a bare shell the analysis
silently resolves against nothing and `docs/` comes out wrong without saying so.

Then verify:

```sh
git status --porcelain -- doc/ docs/
```

**Use `status`, not `git diff`.** Three things make a tree stale and a plain
diff sees only one: a changed page, a new page which is untracked and so
invisible to it, and a page the generator no longer produces, which `git add -A`
would stage away before the diff ran.

Report what changed and why it changed, ie. which source edit the regeneration
is downstream of. If nothing changed, say so; that is the expected result when
the trees were already current.

$ARGUMENTS
