#!/usr/bin/env sh
# vim:set expandtab shiftwidth=4 filetype=sh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/nvim-config.git
# ::: :/.claude/hooks/require-gates.sh
#
#

# PreToolUse on Bash. Refuses a commit while any gate binary is absent.
#
# `.husky/pre-commit` skips a tool it cannot find rather than failing, and
# that is the right call for a hook other people's machines also run: a
# missing formatter should not stop a commit for someone who never asked
# for one. The cost is that the skip is silent, so a Claude Code session
# whose PATH lacks `ts_query_ls` commits `.scm` files that nothing
# formatted and nothing linted, and the `Queries` CI job is the first
# thing that notices.
#
# This hook does not change that behaviour; it stops the commit being
# reached with a gate dark. `lib/tools.sh` will normally have supplied the
# tool by the time this runs, so a block here means mise itself is absent
# or the pin is not installed, and the fix is `mise install`.
#
# `--no-verify` is exempt, since it means the gates were deliberately
# waived and reporting on tools that will not run would only confuse.

set -u

input=$(cat)

command_line=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -n "$command_line" ] || exit 0

case "$command_line" in
    *'git commit'*) ;;
    *) exit 0 ;;
esac

case "$command_line" in
    *--no-verify*) exit 0 ;;
esac

root=${CLAUDE_PROJECT_DIR:-}
[ -n "$root" ] || root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -n "$root" ] || exit 0

lib="$root/.claude/hooks/lib/tools.sh"
[ -r "$lib" ] || exit 0

# shellcheck source=lib/tools.sh
. "$lib"
mise_path

missing=$(require_tools $GATE_TOOLS) && exit 0

printf 'Gate binaries missing from PATH: %s\n\n' "$missing" >&2
printf '.husky/pre-commit skips a gate whose tool it cannot find, so\n' >&2
printf 'committing now would pass through unformatted and unlinted files\n' >&2
printf 'without reporting anything. CI would catch it later.\n\n' >&2
printf 'Install the pins, then retry:\n\n' >&2
printf '    mise install\n\n' >&2
printf 'Commit with --no-verify to waive the gates deliberately.\n' >&2

exit 2
