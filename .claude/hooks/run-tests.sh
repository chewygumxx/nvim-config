#!/usr/bin/env sh
# vim:set expandtab shiftwidth=4 filetype=sh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/nvim-config.git
# ::: :/.claude/hooks/run-tests.sh
#
#

# PostToolUse on Write/Edit. Runs the one test file covering what was
# just written.
#
# The whole suite runs at commit time, which is where a regression in
# the module being edited was otherwise first reported. A single file
# takes between a tenth of a second and about one second, so it can run
# on every edit instead.
#
# The test file is found the way `tests/test_coverage.lua` finds it,
# and from the same source rather than a second copy: the path under
# `lua/` with separators turned into underscores, unless that file's
# `covered_by` table names another. That table is read with `sed`, which
# holds because every entry sits on one line as `["path"] = "file"`; an
# entry written any other way is simply not found, and the edit then runs
# no tests rather than the wrong ones. The few trees `test_coverage.lua`
# deliberately does not cover each have a file of their own below.
#
# Selection is `$MINITEST_PATTERN`, which `util.minitest`'s
# `filter_cases` matches against a case's whole description, the file
# name first. Collection still sources every test file, but defining a
# case is cheap; executing one is what costs. The pattern is anchored and
# ends in a space so that `test_usercmd.lua` does not also select
# `test_usercmd_redirect.lua`. `MINITEST_REPORT` and `MINITEST_SUMMARY`
# are cleared so that a value exported for some other run cannot make
# this one write a report file.
#
# Exit 2 with stderr, because a PostToolUse hook's stderr reaches Claude
# on no other exit code. Like `lint-file.sh`, a failure describes the
# file as it stands, which mid-way through a change of several edits can
# be an intermediate state rather than a mistake.

set -u

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$file" ] || exit 0

root=${CLAUDE_PROJECT_DIR:-}
[ -n "$root" ] || root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -n "$root" ] || exit 0

relative=${file#"$root"/}
[ "$relative" != "$file" ] || exit 0

registry="$root/tests/test_coverage.lua"

# Prints the `covered_by` entry for a path, or nothing.
covered_by() {
    [ -r "$registry" ] || return 0
    _key=$(printf '%s' "$1" | sed 's/[.]/\\./g')
    sed -n "s|^ *\[\"$_key\"\] *= *\"\(tests/test_[a-z0-9_]*\.lua\)\",.*|\1|p" \
        "$registry" | head -n 1
    unset _key
}

case "$relative" in
    tests/test_*.lua) test=$relative ;;
    lua/spec/*.lua | lsp/*.lua) test=tests/test_spec.lua ;;
    queries/*.scm) test=tests/test_queries.lua ;;
    lazy-lock.json) test=tests/test_lockfile.lua ;;
    .claude/*) test=tests/test_claude_assets.lua ;;
    init.lua | lua/*.lua)
        test=$(covered_by "$relative")
        if [ -z "$test" ]; then
            stem=${relative#lua/}
            stem=${stem%.lua}
            test="tests/test_$(printf '%s' "$stem" | tr / _).lua"
        fi
        ;;
    *) exit 0 ;;
esac

[ -f "$root/$test" ] || exit 0

lib="$root/.claude/hooks/lib/tools.sh"
[ -r "$lib" ] || exit 0

# shellcheck source=lib/tools.sh
. "$lib"
mise_path

command -v nvim >/dev/null 2>&1 || exit 0

# A Lua pattern, so the dot is escaped. Test file names hold nothing else
# a pattern treats specially, which `[a-z0-9_]` above relies on.
pattern="^$(printf '%s' "$test" | sed 's/\./%./g') "

if out=$(cd "$root" \
    && MINITEST_PATTERN=$pattern MINITEST_REPORT='' MINITEST_SUMMARY='' \
        nvim --headless -u scripts/minimal_init.lua -l scripts/minitest.lua \
        2>&1); then
    exit 0
fi

# The stdout reporter draws one coloured mark per case, then the failures
# with their tracebacks. Only the second half says anything.
out=$(printf '%s\n' "$out" | sed 's/\x1b\[[0-9;]*m//g')
details=$(printf '%s\n' "$out" | sed -n '/^Fails (/,$p')
[ -n "$details" ] || details=$(printf '%s\n' "$out" | tail -n 40)

printf '%s fails after editing %s:\n\n' "$test" "$relative" >&2
printf '%s\n' "$details" | head -n 80 >&2
printf '\nRerun it alone with:\n\n' >&2
printf "    MINITEST_PATTERN='%s' nvim --headless \\\\\n" "$pattern" >&2
printf '        -u scripts/minimal_init.lua -l scripts/minitest.lua\n' >&2

exit 2
