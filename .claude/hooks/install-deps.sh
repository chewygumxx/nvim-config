#!/usr/bin/env sh
# vim:set expandtab shiftwidth=4 filetype=sh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/nvim-config.git
# ::: :/.claude/hooks/install-deps.sh
#
#

# SessionStart. Installs this repository's npm devDependencies so husky's
# git hooks are wired before anything else in the session runs.
#
# A cloud session starts from a bare clone: `core.hooksPath` is unset until
# something runs `npm ci` or `npm install`, since that is what invokes
# husky's own `prepare` script. Until then `commit-msg` and
# `.husky/pre-commit` never fire, so a commit made early in a session
# silently skips commitlint and every formatter/linter/test gate, and
# nothing reports it. Established by hitting exactly this, by hand, in a
# session before this hook existed.
#
# Remote-only: a local checkout already has a real development setup, and
# re-running this on every editor-attached session would only add latency
# for no benefit.
#
# `npm ci`, not `npm install`: this repository's package.json carries a
# `patchedDependencies` entry for `@commitlint/cz-commitlint`, and the
# committed `package-lock.json` records it as a `patched` block on that
# package's entry. `npm install` re-resolves the tree and silently drops
# that block; `npm ci` installs from the lockfile exactly as committed and
# leaves it untouched. Established by probe: running each in turn and
# diffing `package-lock.json` afterwards. The cost is that `npm ci` always
# deletes and rebuilds `node_modules` from nothing rather than reusing what
# container caching already has, which is a few seconds against this
# repository's devDependencies; that cost buys not silently rewriting a
# committed, patch-tracking lockfile, which is worth more.
#
# Scoped to npm on purpose. `mise install` cannot run here: this
# environment's network policy blocks mise's own download hosts, so the
# gate binaries it pins (luafmt, selene, tombi, lua-language-server, ...)
# stay unavailable regardless of what this hook does. That gap belongs to
# the environment's network policy, not to a repository-committed hook.

set -u

[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0

root=${CLAUDE_PROJECT_DIR:-}
[ -n "$root" ] || root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -n "$root" ] || exit 0

[ -f "$root/package.json" ] || exit 0
command -v npm >/dev/null 2>&1 || exit 0

cd "$root" || exit 0
npm ci
