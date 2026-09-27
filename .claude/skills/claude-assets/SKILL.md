---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/skills/claude-assets/SKILL.md
  #
  #

ctime: 2026-09-27
title: Claude Code assets
name: claude-assets
description: >-
  Add or change anything under .claude/, ie. a skill, a slash command, a
  subagent, a hook or settings.json. Use when a skill does not load, when a
  slash command is unreachable, when a subagent is not selectable, when choosing
  between a hook and a permissions rule, or when tests/test_claude_assets.lua
  fails.
tags:
  - llm
  - claude
---

# Claude Code assets

`.claude/` holds four kinds of asset beside `CLAUDE.md`, and they load on
different terms. `skills/` carries the per-subsystem references that load only
when that subsystem is touched, which is the whole reason `CLAUDE.md` is a
fraction of the length it once was: the reasons did not go away, they stopped
being loaded into every session regardless of relevance. `commands/` holds
`/gate-battery`, `/regen` and `/fresh`. `agents/gate-runner.md` runs the gate
battery without its output reaching the caller. `hooks/` is what makes five
rules mechanical rather than advisory: refusing a write into a generated tree,
refusing a commit while a gate binary is absent, refusing a whole-file read of
the wordlists and the compiled spell file, linting Lua at write time, and
reporting that the generated help has gone stale.

**A newly added agent is not selectable as a `subagent_type` until the session
restarts**, so the session that writes one cannot use it. A skill is not like
that: one written mid-session is announced and reachable within the same
session, which was seen when `claude-assets` itself appeared in the listing
moments after the file was created. Do not generalise the agent's restart
requirement to the other three kinds without probing it.

## A command and a skill share one name namespace

Claude Code lists a command by its filename stem beside a skill by its directory
name, so a collision leaves exactly one of the pair reachable and says nothing
at all about the other. That is why the battery is `/gate-battery` and not the
`/gates` it would otherwise read as: `/gates` lost to the `gates` skill from the
day it was written and sat unreachable for as long as `CLAUDE.md` went on
describing it as the way to run the battery. Established by probe rather than
reasoned about: only one `gates` entry ever reached a session listing and it
carried the skill's description, invoking the name returned the skill's body,
and renaming the command made both appear at once within the same session.

`tests/test_claude_assets.lua` asserts the two sets of names are disjoint, which
nothing did before: it had always checked skills, commands and agents as three
independent groups, so a shadowed command passed every case. Agents are a
separate namespace, chosen by `subagent_type` rather than by slash, so
`gate-runner` can sit beside both without shadowing either.

## Frontmatter

A skill's `description` is the only thing deciding whether it loads, so write it
as the situations that should reach for it rather than as a summary of its
contents.

**Fold every description with `>-` and never leave a bare `description:`.** The
reflow hook rewraps a long value either way, but a bare key yields a plain
multiline scalar, which is valid YAML that **cannot contain `": "`**; `>-` folds
to the same single line and tolerates a colon anywhere. Established by probe,
and now asserted for skills, commands and agents alike, since a command whose
description drifted back would break only once somebody later wrote a
colon-space into it, which is the quietest possible failure.

A skill declares `name:` matching its directory and an agent declares `name:`
matching its filename stem, because that is what each loader keys on. A command
declares no name at all: its filename is the slash command. Every asset also
carries the repository's Markdown document head, ie. the `__cgxx:` block,
`ctime`, `title` and `tags`.

## Prefer a hook to a `permissions.deny` rule

A `Read(...)` rule is not scoped to the Read tool. Claude Code recognises
file-naming commands inside Bash and applies the rule to those too, so
`Read(/words.txt)` also denies `head -3 words.txt`, `wc -l words.txt` and
`ls -la words.txt`, and blocks Edit and Write on the path besides. That was
established by adding the rule and running each command rather than reasoned
about. A `PreToolUse` hook blocks just as hard, since exit 2 stops a call before
permission rules are evaluated, but it leaves Bash alone and can name the cheap
route instead of merely refusing.

Every hook wired in `settings.json` has to be executable, which the suite
checks, and it checks that the table is non-empty in the same case so that a
shape change cannot pass as "nothing broken".

## `hooks/lib/tools.sh`

Source it before running any gate by hand. mise is not activated in a Claude
Code shell, so without its `PATH` prefix `ts_query_ls` is absent entirely and
`.husky/pre-commit` skips the whole tree-sitter query gate in silence, while
`luafmt` and the two `emmylua` binaries resolve to a cargo build rather than to
the pin. Do not reach for `mise exec` instead: `mise.toml` pins the editor
toolchain beside the gates, so it begins installing 22 tools before it answers.

## What the suite can and cannot check

`tests/test_claude_assets.lua` checks that every rooted path the prose names
still exists, the frontmatter rules above, the command-versus-skill namespace,
that every skill is pointed at from `.claude/CLAUDE.md` by the phrase
`` `<name>` skill `` and that no such phrase names a skill that is gone. It
cannot check that any of the prose is _true_. Its `not_a_path` registry excludes
tokens that look like paths and deliberately name nothing, and it asserts in
both directions: an entry naming a file that now exists fails, and so does an
entry nothing under `.claude/` mentions any more. Deleting a passage that
carried the only mention of an excluded token means editing that registry in the
same commit.

`/fresh` is the end-of-session pass over the half no gate can reach.
