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
  subagent, a path-scoped rule, a hook or settings.json. Use when a skill does
  not load, when a slash command is unreachable, when a subagent is not
  selectable, when a rule loads in every session or in none, when choosing
  between a hook and a permissions rule, or when tests/test_claude_assets.lua
  fails.
tags:
  - llm
  - claude
---

# Claude Code assets

`.claude/` holds four kinds of asset beside `CLAUDE.md`, and they load on
different terms. `skills/` carries two things: the per-subsystem references that
load only when that subsystem is touched, which is the whole reason `CLAUDE.md`
is a fraction of the length it once was, and the four slash-invoked workflows,
`/gate-battery`, `/regen`, `/fresh` and `/new-server`. The reasons did not go
away when `CLAUDE.md` shrank, they stopped being loaded into every session
regardless of relevance. `agents/gate-runner.md` runs the gate battery without
its output reaching the caller, and `agents/lock-bump-reviewer.md` reads the
upstream commits a `lazy-lock.json` change pulls in the same way. `rules/` holds
a warning per tree that needs one, loaded by path rather than by prompt, which
is what makes a rule the cheapest place to put anything triggered by a path:
unlike a skill, whose description is resident in every session, a rule costs
nothing until something in its scope is read. `hooks/` is what makes five rules
mechanical rather than advisory: refusing a write into a generated tree,
refusing a commit while a gate binary is absent, refusing a whole-file read of
the wordlists and the compiled spell file, linting every language
`.husky/pre-commit` gates at write time, and reporting that the generated help
has gone stale. `run-tests.sh` brings the suite forward the same way, running
the one test file that covers what was just written, found by
`tests/test_coverage.lua`'s derivation and its `covered_by` table rather than a
copy of either. Another hook, `install-deps.sh`, is not one of these: it fires
on `SessionStart` rather than `PreToolUse`/`PostToolUse`, and it bootstraps a
cloud session's `node_modules` rather than making an advisory rule mechanical.
See `install-deps.sh` below for why it exists and what it deliberately leaves
alone.

**A newly added agent is not selectable as a `subagent_type` until the session
restarts**, so the session that writes one cannot use it. A skill is not like
that: one written mid-session is announced and reachable within the same
session, which was seen when `claude-assets` itself appeared in the listing
moments after the file was created, and again when the three workflows were
announced under their new names in the same session that moved them there. Do
not generalise the agent's restart requirement to the other kinds without
probing it.

## Write a skill, not a command

[Commands and skills are one mechanism](https://code.claude.com/docs/en/claude-directory#ce-commands).
A file at `commands/<name>.md` produces `/<name>` exactly as
`skills/<name>/SKILL.md` does, both can be invoked by name or reached on their
description, and the frontmatter is the same set of fields save that a command
reads no `name` and no `paths`. The documentation's advice is a skill for new
work, with commands remaining supported, so this is a preference rather than a
deprecation.

There is therefore no `commands/` here, and two things decide it. A skill is a
directory, so it can bundle a reference file, a template or a script beside its
prose, which one Markdown file cannot. And a skill can carry `paths`, so it
could be scoped to a tree the way a rule is, which a command has no way to
express. Neither is about the name: a skill's slash name comes from its
directory just as a command's comes from its filename, so renaming either means
moving a file.

The unification is observable from inside a session rather than only asserted.
Before the three were moved, `/context` already priced `fresh`, `gate-battery`
and `regen` under its `Skills` heading beside the subject-matter skills, and the
session listing carried all ten with nothing separating the two kinds. The
harness had stopped distinguishing them; only the tree still did.

## A command and a skill share one name namespace

This is why the battery answers to `gate-battery` rather than the `gates` it
would otherwise read as. Claude Code lists a command by its filename stem beside
a skill by its directory name, so a collision leaves exactly one of the pair
reachable and says nothing at all about the other. `/gates` lost to the `gates`
skill from the day it was written and sat unreachable for as long as `CLAUDE.md`
went on describing it as the way to run the battery. Established by probe rather
than reasoned about: only one `gates` entry ever reached a session listing and
it carried the skill's description, invoking the name returned the skill's body,
and renaming it made both appear at once within the same session.

The hazard cannot arise between two skills, a directory name being unique by
construction, so adding a command back is now the only route to it. That is why
`tests/test_claude_assets.lua` goes on asserting the two sets of names are
disjoint over a `commands/` glob matching nothing, rather than dropping a case
that reads as dead. Nothing asserted it before the rename: the suite had always
checked skills, commands and agents as three independent groups, so a shadowed
command passed every case. Agents are a separate namespace, chosen by
`subagent_type` rather than by slash, so `gate-runner` can sit beside both
without shadowing either.

## A rule is scoped by `paths` and nothing else

`rules/` is the one asset kind that loads off a file path rather than off a
prompt or a name. Every `.md` file under it is discovered recursively, so
`.claude/rules/doc.md` is found and the same name without its extension is not
found at all.

**`paths` is the only field Claude Code reads from a rule, and every other field
is ignored without an error.** That is what makes the singular `path:` the trap
worth knowing: it does not fail, it produces a rule with no `paths` at all, and
a rule with no `paths` loads at launch with the same priority as
`.claude/CLAUDE.md`. The typo therefore presents as the feature working, while
quietly doing the opposite of the intent. `tests/test_claude_assets.lua` asserts
against it in both directions, since a rule that lost its `paths` in an edit
looks identical from outside. If the YAML between the markers does not parse at
all, the frontmatter is ignored and the rule loads unscoped by the same route;
`claude --debug` is where that parse error is reported.

The other half worth knowing is when a scoped rule fires: **on a read of a
matching file, not on every tool use.** That is what bounds a rule against a
hook rather than making one redundant. `.claude/rules/doc.md` and
`.claude/rules/docs.md` say why the generated trees are never hand-edited, and
`.claude/hooks/block-generated.sh` still refuses the write, because a Write to a
path nothing read first reaches the hook and never reaches the rule.

Both directions were established by probe rather than reasoned about, since only
the forward one is easy to see and an unscoped rule presents as a working one. A
`claude -p` session told to read `doc/tags` and quote whatever it had been told
about `doc/` returned `.claude/rules/doc.md` verbatim and without its
frontmatter; the same question asked of a session that read nothing returned
only this repository's `CLAUDE.md` prose, with no wording from either rule in
it.

Claude Code strips the whole frontmatter before loading a rule into context, so
the repository's document head costs nothing there.

## Frontmatter

A skill's `description` is the only thing deciding whether it loads, so write it
as the situations that should reach for it rather than as a summary of its
contents.

**Fold every description with `>-` and never leave a bare `description:`.** The
reflow hook rewraps a long value either way, but a bare key yields a plain
multiline scalar, which is valid YAML that **cannot contain `": "`**; `>-` folds
to the same single line and tolerates a colon anywhere. Established by probe,
and now asserted for skills and agents alike, and for a command if one is ever
added, since an asset whose description drifted back would break only once
somebody later wrote a colon-space into it, which is the quietest possible
failure.

A skill declares `name:` matching its directory and an agent declares `name:`
matching its filename stem. For the agent that is what the loader keys on. For
the skill it is a consistency rule rather than a mechanism, and the reason is
worth stating because the obvious one is wrong: **a skill loads and is
advertised under its directory name whether or not it declares a `name:` at
all.** A probe skill in `probe-dir/` declaring `name: probe-renamed` was
advertised to a fresh session as `probe-dir`, and the three workflows here were
announced under their new directory names in the moment they were moved, before
any `name:` had been added to them. But `Skill(skill = "probe-renamed")` then
succeeded on its first call. So a `name:` that disagrees with its directory does
not rename the skill, it gives it a second address that nothing advertises, and
the assertion exists to keep a file from claiming a name the listing will not
show.

A command declares no name at all: its filename is the slash command. A rule
declares neither, and no `description` either, which is why the description
cases skip `rules/` rather than having been forgotten there. Every asset also
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

`lint-file.sh` is `PostToolUse`, so it reports on a write that has already
landed rather than refusing one, and it fires per edit. A change that introduces
a local before the edit that consumes it therefore reports `unused_variable` on
the intermediate state, twice in a row if the consumer takes two edits. Read a
failure there as a description of the file as it stands, not as an edit that was
rejected.

## `install-deps.sh`

The one `SessionStart` hook here, and the answer to "why does a cloud session
need `bun install` run by hand": a cloud session starts from a bare clone, and
`core.hooksPath` stays unset, husky's git hooks stay unwired, and
`commit-msg`/`.husky/pre-commit` never fire, until something runs `bun install`.
Nothing about that is specific to this repository; it is true of any project
that gates commits through husky. Established by doing exactly this by hand
mid-session, more than once, before the hook existed: a commit went through with
no `Claude-Session:` trailer question or gate failure reported at all, because
nothing was wired to ask either question.

It runs only when `$CLAUDE_CODE_REMOTE` is `true`, and it deliberately does not
attempt `mise install`. Both are the same fact stated from two directions: a
cloud environment's network policy can block the hosts `mise` downloads from
(established by probe, in a session where `mise install` hung against exactly
those hosts), and a hook committed to this repository cannot change that policy.
Fixing it, if it needs fixing, is an environment setting, not a `.claude/`
change; the gate binaries `mise` would otherwise supply stay whatever they were
before this hook ran.

It runs `bun install`, not `bun install --frozen-lockfile`, for the general
reason: this hook fires on every session start, and a lockfile that has drifted
from `package.json` should not leave a session with no hooks at all. That was
not always safe here, back when the project was on npm. `package.json` once
carried a pnpm-only `patchedDependencies` entry for `@commitlint/cz-commitlint`,
inert under npm (nothing in this project's scripts ever applied `patches/`), and
`npm install`'s re-resolution silently dropped the matching `patched` block from
`package-lock.json` on every run while `npm ci` left it alone, which made
`install` unsafe for a hook that should leave the tree clean. No dependency is
patched any more: the prompt's titles come from the `@chewygumxx/cz-commitlint`
adapter that `config.commitizen.path` names, so nothing in dependency resolution
depends on a field only pnpm understands, nor on a `postinstall` script.
Verified by probe since the move to Bun: a clean `bun install` reproduces
`bun.lock` byte-for-byte against what is committed, both from nothing and
repeated on top of itself.

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
that every rule scopes itself with `paths` and none with the singular `path`,
that every _reference_ skill is pointed at from `.claude/CLAUDE.md` by the
phrase `` `<name>` skill `` and that no such phrase names a skill that is gone.
It cannot check that any of the prose is _true_.

Two registries carry the exceptions, and both are asserted in both directions,
since an exemption nothing exempts is the quiet kind of stale. `not_a_path`
excludes tokens that look like paths and deliberately name nothing, so an entry
naming a file that now exists fails, and so does an entry nothing under
`.claude/` mentions any more; deleting a passage that carried the only mention
of an excluded token means editing that registry in the same commit. `workflow`
names the skills reached by slash rather than by being routed to, exempting them
from the pointer rule, because a workflow holds no reason and
`.claude/CLAUDE.md`'s table says where a reason lives. Nothing is lost by
leaving one out of it: a skill's `description` is resident in every session
regardless, so discovery never depended on the pointer. What the pointer serves
is a subagent with no `Skill` tool, ie. `gate-runner`, for which the table is
the only thing naming the file to read, and which could not invoke a workflow
anyway.

It also caps `.claude/CLAUDE.md` at 1200 words. That file is the only one here
loaded into every session and every subagent regardless of relevance, and
hand-restraint demonstrably does not hold it: on 2026-09-27 it went from 8609
words to 2432 across seven extraction commits and was back to 2506 within the
hour. A failure there is an instruction to move a reason somewhere narrower
rather than to write a shorter one, since a skill and a rule both cost nothing
until something in scope is read.

Its reach stops at `.claude/`. **No workflow or hook globs `*.md`**: prettier
takes `*.json`, `*.jsonc`, `*.yaml` and `*.yml` and nothing else, in both
`.husky/pre-commit` and CI. A Markdown file outside `.claude/` is therefore
reached by no gate at all. That is one more reason the per-directory notes are
rules under `.claude/rules/` rather than `CLAUDE.md` files beside the code they
describe: a path a rule names is checked like any other, where a directory
`CLAUDE.md` would rely entirely on care at write time.

`/fresh` is the end-of-session pass over the half no gate can reach.
