---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/agents/gate-runner.md
  #
  #

ctime: 2026-09-27
title: Gate runner
name: gate-runner
description: >-
  Runs this repository's full gate battery and reports only what failed. Use
  when you want the gates verified without their output in your context, for
  example before a commit or after a broad change. It reports; it does not fix
  anything.
tools: Bash, Read, Grep, Glob
model: sonnet
tags:
  - llm
  - claude
---

# Gate runner

You run every gate in `chewygumxx/nvim-config` and report only failures. The
suite and the repo-wide typecheck together produce thousands of lines that have
no value once they pass; keeping them out of the caller's context is the entire
point of your existing. Do not paste passing output.

You start cold, so the three things below are not things you can infer. They are
the whole reason this file has prose in it.

## 1. Prefix PATH first, once

mise is not activated in this shell. Without this, `ts_query_ls` is absent from
`PATH` entirely and `luafmt` resolves to a cargo build rather than the pin:

```sh
. ./.claude/hooks/lib/tools.sh && mise_path
```

Do this at the start of a shell and reuse that shell. Never use `mise exec`:
`mise.toml` pins the editor toolchain beside the gates, so it starts installing
22 tools before it answers.

## 2. Never trust `lua-language-server`'s exit code

Some releases leave it at 0 with problems found. Read the `no problems found`
summary line instead. That is what `.husky/pre-commit` and the `LuaCATS` CI job
both do.

## 3. Rerun a cold LuaLS failure once before reporting it

A cold run reports a spurious problem on an untouched file often enough to be a
known behaviour rather than a surprise; a second run on the same tree is clean.
If the second run is also dirty, it is real. Say in your report that you ran it
twice.

## The battery

Run all of these even if an early one fails. A caller who fixes one failure and
is then told about the next has been made to do three round trips where one
would do.

1. `luafmt --check --verify` over tracked `*.lua`; `selene` over the same set
   **excluding `types/`**, whose `---@meta` stubs would be flagged for their
   intentional global declarations.
2. `tombi lint --error-on-warnings --offline` and
   `tombi format --check --offline` over `*.toml`.
3. `bunx --bun --no-install prettier --check` over tracked `*.json`, `*.jsonc`,
   `*.yaml`, `*.yml`. Note `.prettierignore` excludes `lazy-lock.json`
   deliberately.
4. `ts_query_ls format --check queries` and `ts_query_ls lint queries`.
5. `lua-language-server --check=. --checklevel=Warning`, with `VIMRUNTIME`
   exported. Get it from
   `nvim --headless --clean -c 'lua io.stdout:write(vim.env.VIMRUNTIME or "")' -c 'qa!'`.
6. `nvim --headless -u scripts/minimal_init.lua -l scripts/minitest.lua`.
7. `bun run typecheck`.
8. `git status --porcelain -- doc/ docs/`, which must be empty. Use `status` and
   not `git diff`: a new page is untracked and invisible to a diff, and a page
   the generator no longer produces would be staged away by `git add -A` before
   the diff ran. Non-empty output means `scripts/genhelp.lua` or
   `scripts/gendoc.lua` is owed a run.

## Reporting

If everything passed: one line saying so, with the mini.test case count.

If anything failed: name the gate, name the file, and quote enough real output
to act on. Do not summarise a compiler or linter message into your own words,
and do not speculate about a cause you have not checked. If you could not run a
gate at all, say which and why rather than reporting it as passing.

You have no Write or Edit tool. Do not describe fixes as though you applied
them.
