---
__cgxx: |
  # vim:set expandtab shiftwidth=2 filetype=markdown foldlevel=3:
  # SPDX-License-Identifier: GPL-3.0-only

  #
  #
  # ~chewygumxx/nvim-config.git
  # ::: :/.claude/skills/fresh/SKILL.md
  #
  #

ctime: 2026-09-27
title: Session freshness pass
name: fresh
description: >-
  Judge whether this session left the assets under .claude/ still true. The
  mechanical checks are a gate now, so this is the half that needs a person.
tags:
  - llm
  - claude
---

Run this before concluding a session.

## The mechanical half is no longer your job

`tests/test_claude_assets.lua` asserts all of it: that every rooted path the
assets name still exists, that every skill, command and agent folds its
description with `>-`, that every skill and agent declares the name it is filed
under, that every hook in `.claude/settings.json` points at something
executable, and that every skill is pointed at from `.claude/CLAUDE.md` with no
pointer naming a skill that is gone. It runs in `.husky/pre-commit` on any
commit touching `lua/`, `tests/`, `scripts/`, `lsp/`, `queries/` or `init.lua`,
and in CI on every push. The `Help` and `Docs` jobs cover `doc/` and `docs/`.

A `.claude/`-only commit deliberately runs no suite, so if this session touched
nothing else and you want those checks now rather than at CI:

```sh
MINITEST_PATTERN='claude assets' nvim --headless -u scripts/minimal_init.lua -l scripts/minitest.lua
```

Do not re-derive any of those checks by hand here. Duplicating a gate in prose
is how the prose and the gate come to disagree, and the prose is the copy that
loses quietly.

## What no gate can reach

**Whether the prose is true.** A skill whose explanation has quietly become
wrong passes every assertion above, because every path it names still resolves.
`.claude/skills/fresh/SKILL.md` itself went stale within an hour of being
written, by instructing four checks a gate had just taken over, and nothing
mechanical noticed.

So the rest of this is judgement, not verification, and it runs on recollection
of the session rather than on a record of it. After a compaction that
recollection is partial. Say so rather than implying coverage you do not have.

1. **Did this session establish anything by probe that is not written down?** A
   behaviour confirmed by running something, rather than reasoned about, is
   exactly what these files are for. A reason goes in the skill that owns the
   subsystem, or in that directory's own `CLAUDE.md` when it is a rule for
   anything written there, or in `.claude/CLAUDE.md` only when it bears on every
   edit. Prefer the narrowest of the three that reaches the reader who needs it,
   since the last is loaded into every session regardless of relevance. A fact
   goes in the README or a doc comment.

2. **Did this session contradict anything already written?** Prose that
   disagrees with the tree is the failure this whole arrangement exists to
   prevent. Correct it where it is wrong rather than adding a second account
   beside it, and check whether the contradiction reaches further than the
   paragraph you noticed it in.

3. **Did a skill fail to load when it should have, or load when it should not?**
   The frontmatter `description` is the only thing deciding that. A skill that
   was relevant and stayed quiet is missing the words that would have summoned
   it, and that is a fix to the description rather than to the body.

4. **Did anything here take over work that a gate could do instead?** The
   mechanical half of this file used to be four hand-run checks. If a judgement
   item above has become mechanical, move it into `tests/test_claude_assets.lua`
   and delete it from here.

Report what you changed, and what you checked and found already correct. Say
plainly if something is stale and you have not fixed it.

$ARGUMENTS
