---
description:
  Check every Claude asset under .claude/ is still true of the tree before
  concluding
---

Run this before concluding a session. It has a mechanical half you can check
outright and a judgement half you have to think about.

## Mechanical

1. **Hook paths resolve.** Every `command` in `.claude/settings.json` must point
   at a file that exists and is executable:

   ```sh
   jq -r '.hooks[][].hooks[].command' .claude/settings.json \
       | sed "s|\${CLAUDE_PROJECT_DIR}|$PWD|" \
       | while read -r p; do [ -x "$p" ] && echo "ok   $p" || echo "FAIL $p"; done
   ```

2. **Skill frontmatter parses.** Each `.claude/skills/*/SKILL.md` needs a `name`
   matching its directory, and a `description` written as a folded block scalar,
   ie. `description: >-` with the text indented beneath it. The `.md` reflow
   hook rewraps any long description, and a bare `description:` becomes a plain
   multiline scalar that is valid YAML but **cannot contain `": "`**. `>-` folds
   to the same single line and tolerates a colon anywhere, which is why it is
   the form used here; that was established by probe rather than assumed. A
   skill that has drifted back to the bare form is one colon away from breaking
   silently.

3. **Every path a skill names still exists.** Collect the backticked paths out
   of `.claude/skills/*/SKILL.md`, `.claude/commands/*.md` and
   `.claude/CLAUDE.md`, and check each against the tree. A renamed or deleted
   module leaves the prose describing something that is not there, which is
   worse than saying nothing.

4. **Every pointer in `.claude/CLAUDE.md` names a skill that exists**, and every
   skill is pointed at from there.

5. **The generated trees are clean**: `git status --porcelain -- doc/ docs/` is
   empty.

## Judgement

6. **Did this session establish anything by probe that is not written down?** A
   behaviour confirmed by running something, rather than reasoned about, is
   exactly what these files are for. Put a reason in the relevant skill or in
   `.claude/CLAUDE.md`, and a fact in the README or a doc comment.

7. **Did this session contradict anything already written?** Prose that
   disagrees with the tree is the failure mode this whole arrangement exists to
   prevent. Correct it where it is wrong rather than adding a second account
   beside it.

8. **Did a skill fail to load when it should have, or load when it should not?**
   The frontmatter `description` is the only thing deciding that. If a skill was
   relevant and stayed quiet, its description is missing the words that would
   have summoned it.

Report what you changed and what you checked and found already correct. Say
plainly if something is stale and you have not fixed it.

$ARGUMENTS
