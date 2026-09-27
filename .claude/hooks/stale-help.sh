#!/usr/bin/env sh
# vim:set expandtab shiftwidth=4 filetype=sh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/nvim-config.git
# ::: :/.claude/hooks/stale-help.sh
#
#

# PostToolUse on Write/Edit. Reports that `doc/` has gone stale.
#
# `scripts/genhelp.lua` harvests by calling `setup()` on `option`,
# `keymap`, `filetype`, `autocmd` and `usercmd` under a stub of the API
# each writes through, and reads every spec's `keys` statically. So a
# change anywhere in those five module trees, or to a spec, can change
# the rendered help without touching `doc/` itself, and the `Help` CI job
# is where that surfaces.
#
# It deliberately does not run the generator. A generator does not belong
# in an automatic path, for the same reason `.husky/pre-commit` excludes
# both of them: it rewrites a whole tracked tree, and that has to be a
# thing somebody asked for. This only says that it is now owed.
#
# `lua/filetype/` is in the list although the plan that produced this
# hook named only the other four. `genhelp.lua` calls
# `require("filetype").setup()` alongside them, so a detection pattern
# added there reaches the rendered page the same way.
#
# Exit 2 with stderr, because a PostToolUse hook's stderr reaches Claude
# on no other exit code.

set -u

input=$(cat)

file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$file" ] || exit 0

root=${CLAUDE_PROJECT_DIR:-}
[ -n "$root" ] || root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -n "$root" ] || exit 0

relative=${file#"$root"/}
[ "$relative" != "$file" ] || exit 0

case "$relative" in
    lua/option/*.lua | lua/keymap/*.lua | lua/filetype/*.lua | \
    lua/usercmd/*.lua | lua/spec/*.lua | lua/autocmd.lua) ;;
    *) exit 0 ;;
esac

# Already stale before this edit, so the reminder is owed to whatever
# made it stale rather than to this call. Saying it twice is noise.
if [ -n "$(cd "$root" && git status --porcelain -- doc/ 2>/dev/null)" ]; then
    exit 0
fi

printf '%s feeds the generated :help, which is now stale.\n\n' "$relative" >&2
printf 'scripts/genhelp.lua harvests mappings, user commands, options and\n' >&2
printf 'autocommands by running each setup() under a stub, and reads every\n' >&2
printf "spec's keys statically, so this edit can change doc/ without\n" >&2
printf 'touching it. The Help CI job fails on the difference.\n\n' >&2
printf 'Regenerate before committing:\n\n' >&2
printf '    nvim --headless -u scripts/minimal_init.lua -l scripts/genhelp.lua\n' >&2

exit 2
