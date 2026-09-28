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
# `npm install`, not `npm ci`: this hook runs on every session start
# (`startup`, `resume`, `clear` and `compact` alike), and `npm install` is
# the one that reuses container-cached `node_modules` instead of deleting
# and rebuilding it from nothing every time. It is genuinely idempotent
# here: `package.json`'s `postinstall` (`patch-package`) is what actually
# applies `patches/@commitlint+cz-commitlint+21.2.2.patch` now, so nothing
# about dependency resolution depends on pnpm-only lockfile fields the way
# it briefly did. Verified by probe: a clean `npm install` reproduces
# `package-lock.json` byte-for-byte against what is committed, both from
# nothing and repeated on top of itself.
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
npm install
