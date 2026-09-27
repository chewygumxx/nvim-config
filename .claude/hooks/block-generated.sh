#!/usr/bin/env sh
# vim:set expandtab shiftwidth=4 filetype=sh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/nvim-config.git
# ::: :/.claude/hooks/block-generated.sh
#
#

# PreToolUse on Write/Edit. Refuses any path inside a generated tree.
#
# Both generators `delete(dir, "rf")` and recreate, so a file written into
# `doc/` or `docs/` by hand is removed on the next run without a word.
# That was confirmed by planting a file in each and running them: neither
# said anything. It also rules out leaving a warning beside the output,
# which is why this hook exists and why neither directory can carry a
# `CLAUDE.md` of its own.
#
# The block is exit 2 with stderr rather than a `permissionDecision` of
# `deny`, because the two route identically and this way the reason is
# one `printf` rather than assembled JSON.

set -u

input=$(cat)

file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$file" ] || exit 0

# Claude Code expands `~` and relative paths before a hook runs, so this
# is always absolute and cannot be dodged by respelling it.
root=${CLAUDE_PROJECT_DIR:-}
[ -n "$root" ] || root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -n "$root" ] || exit 0

case "$file" in
    "$root"/doc/*)
        tree='doc/'
        what='the generated :help file'
        script='scripts/genhelp.lua'
        ;;
    "$root"/docs/*)
        tree='docs/'
        what='the generated LuaCATS reference'
        script='scripts/gendoc.lua'
        ;;
    *)
        exit 0
        ;;
esac

printf '%s is %s and is never edited by hand.\n\n' "$tree" "$what" >&2
printf 'The generator deletes the whole tree and recreates it, so this\n' >&2
printf 'edit would vanish on the next run with nothing reported. Change\n' >&2
printf 'the source it is rendered from, then regenerate:\n\n' >&2
printf '    nvim --headless -u scripts/minimal_init.lua -l %s\n\n' "$script" >&2
printf 'Verify with `git status --porcelain -- %s` rather than a diff.\n' "$tree" >&2

exit 2
