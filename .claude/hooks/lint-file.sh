#!/usr/bin/env sh
# vim:set expandtab shiftwidth=4 filetype=sh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/nvim-config.git
# ::: :/.claude/hooks/lint-file.sh
#
#

# PostToolUse on Write/Edit. Formats and lints the one file just written.
#
# This is `.husky/pre-commit`'s `lintfmt_*` functions narrowed to a single
# file and made non-destructive: every formatter runs in its check mode
# rather than writing, because a hook that rewrote the file under a Write
# tool call would leave the tool's own record of what it wrote
# disagreeing with the disk. The commit-time hook still does the writing,
# which is why each report names the command that would.
#
# It was Lua-only once, and the other four languages the commit-time hook
# gates were then caught only by a rejected commit: an `.scm` query that
# `ts_query_ls lint` refuses, or a `mise.toml` that `tombi` does, reached
# nothing between the write and `git commit`. The dispatch below is the
# commit-time hook's set and nothing more, so a language this reports on
# is exactly one a commit would be refused for.
#
# `selene` is held back from `types/` for the reason `.husky/pre-commit`
# holds it back: those files are `---@meta` declaration stubs, never
# required or executed, and their intentional global declarations would
# be flagged as real-code bugs.
#
# prettier is reached through `node_modules` rather than `bunx` alone.
# `--no-install` makes a missing package an error rather than a
# download, and that error would otherwise read as a problem in the
# file, so a checkout that has not run `bun install` is skipped instead.
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
    *.lua | *.scm | *.toml | *.json | *.jsonc | *.yaml | *.yml) ;;
    *) exit 0 ;;
esac

[ -f "$file" ] || exit 0

root=${CLAUDE_PROJECT_DIR:-}
[ -n "$root" ] || root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -n "$root" ] || exit 0

# Only this repository's own files. One edited elsewhere in the session
# is none of this hook's business and has none of its configuration.
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

# Runs one check from the repository root and appends its output to the
# report under the given label when it fails.
check() {
    _label=$1
    shift
    if ! _out=$(cd "$root" && "$@" 2>&1); then
        report="${report}${_label}:
${_out}
"
        status=1
    fi
    unset _label _out
}

case "$relative" in
    *.lua)
        fix="luafmt --write -- $relative"
        if command -v luafmt >/dev/null 2>&1; then
            check luafmt luafmt --check --verify -- "$relative"
        fi
        case "$relative" in
            types/*) ;;
            *)
                if command -v selene >/dev/null 2>&1; then
                    check selene selene -- "$relative"
                fi
                ;;
        esac
        ;;
    *.scm)
        fix="ts_query_ls format $relative, twice, as .husky/pre-commit does"
        if command -v ts_query_ls >/dev/null 2>&1; then
            check 'ts_query_ls format' ts_query_ls format --check "$relative"
            check 'ts_query_ls lint' ts_query_ls lint "$relative"
        fi
        ;;
    *.toml)
        fix="tombi format --offline $relative"
        if command -v tombi >/dev/null 2>&1; then
            check 'tombi lint' tombi lint --error-on-warnings --offline \
                "$relative"
            check 'tombi format' tombi format --check --offline "$relative"
        fi
        ;;
    *)
        fix="bunx --bun --no-install prettier --write $relative"
        if command -v bunx >/dev/null 2>&1 \
            && [ -e "$root/node_modules/.bin/prettier" ]; then
            check prettier bunx --bun --no-install prettier --check \
                "$relative"
        fi
        ;;
esac

[ "$status" -eq 0 ] && exit 0

printf '%s reports problems:\n\n%s\n' "$relative" "$report" >&2
printf 'Fix these now rather than at commit time, where .husky/pre-commit\n' >&2
printf 'would refuse the commit or rewrite and re-stage the file. The\n' >&2
printf 'formatting half is fixed by running:\n\n    %s\n' "$fix" >&2

exit 2
