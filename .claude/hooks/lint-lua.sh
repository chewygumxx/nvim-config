#!/usr/bin/env sh
# vim:set expandtab shiftwidth=4 filetype=sh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/nvim-config.git
# ::: :/.claude/hooks/lint-lua.sh
#
#

# PostToolUse on Write/Edit. Formats and lints the one file just written.
#
# This is `.husky/pre-commit`'s `lintfmt_lua` narrowed to a single file
# and made non-destructive: `--check --verify` rather than `--write`,
# because a hook that rewrote the file under a Write tool call would
# leave the tool's own record of what it wrote disagreeing with the disk.
# The commit-time hook still does the writing.
#
# `selene` is held back from `types/` for the reason `.husky/pre-commit`
# holds it back: those files are `---@meta` declaration stubs, never
# required or executed, and their intentional global declarations would
# be flagged as real-code bugs.
#
# Reporting is exit 2 with stderr, which is the only route by which a
# PostToolUse hook's stderr reaches Claude at all: on exit 0 it goes to
# the debug log and is never seen. The tool has already run either way,
# so this is feedback rather than a block.

set -u

input=$(cat)

file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$file" ] || exit 0

case "$file" in
    *.lua) ;;
    *) exit 0 ;;
esac

[ -f "$file" ] || exit 0

root=${CLAUDE_PROJECT_DIR:-}
[ -n "$root" ] || root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -n "$root" ] || exit 0

# Only this repository's own Lua. A Lua file edited elsewhere in the
# session is none of this hook's business and has no `selene.toml`.
case "$file" in
    "$root"/*) ;;
    *) exit 0 ;;
esac

relative=${file#"$root"/}

lib="$root/.claude/hooks/lib/tools.sh"
[ -r "$lib" ] || exit 0

# shellcheck source=lib/tools.sh
. "$lib"
mise_path

status=0
report=''

if command -v luafmt >/dev/null 2>&1; then
    if ! out=$(cd "$root" && luafmt --check --verify -- "$relative" 2>&1); then
        report="${report}luafmt:
${out}
"
        status=1
    fi
fi

case "$relative" in
    types/*) ;;
    *)
        if command -v selene >/dev/null 2>&1; then
            if ! out=$(cd "$root" && selene -- "$relative" 2>&1); then
                report="${report}selene:
${out}
"
                status=1
            fi
        fi
        ;;
esac

[ "$status" -eq 0 ] && exit 0

printf '%s reports problems:\n\n%s\n' "$relative" "$report" >&2
printf 'Fix these now rather than at commit time, where .husky/pre-commit\n' >&2
printf 'would rewrite the file with `luafmt --write` and re-stage it.\n' >&2

exit 2
