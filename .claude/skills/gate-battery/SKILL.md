---
ctime: 2026-09-27
mtime: 2026-10-05
spdx: GPL-3.0-only
title: Gate battery
name: gate-battery
description: >-
  Run every local gate in the order CI runs them and report only failures
tags:
  - llm
  - claude
---

<!--
   -
   - ~chewygumxx/nvim-config.git
   - ::: :/.claude/skills/gate-battery/SKILL.md
   -
   -->

Run this repository's full gate battery locally. Invoke the `gates` skill first
for the detail behind each step, then work through the sequence below.

Prefix `PATH` once, at the start, and reuse that shell for every step:

```sh
. ./.claude/hooks/lib/tools.sh && mise_path
```

Then, in order:

1. `luafmt --check --verify` over every tracked `*.lua`, then `selene` over the
   same set excluding `types/`.
2. `tombi lint --error-on-warnings --offline` and
   `tombi format --check --offline` over every `*.toml`.
3. `bunx --bun --no-install prettier --check` over every tracked `*.json`,
   `*.jsonc`, `*.yaml` and `*.yml`.
4. `ts_query_ls format --check queries` and `ts_query_ls lint queries`.
5. `lua-language-server --check=. --checklevel=Warning`, with `VIMRUNTIME`
   exported. **Read the `no problems found` summary line rather than the exit
   code**, which some releases leave at 0 with problems found. If it reports a
   problem on a file this session did not touch, run it a second time before
   believing it: a cold run flakes, and a second run on the same tree is clean.
6. `nvim --headless -u scripts/minimal_init.lua -l scripts/minitest.lua`.
7. `bun run typecheck`.
8. `git status --porcelain -- doc/ docs/`, which must be empty. Use `status` and
   not `git diff`, for the reason the `generated-output` skill gives.

Report only what failed, with enough output to act on. If everything passed, say
so in one line with the test count.

$ARGUMENTS

<!-- vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3: -->
