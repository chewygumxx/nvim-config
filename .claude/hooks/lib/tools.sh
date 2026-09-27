# vim:set expandtab shiftwidth=4 filetype=sh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/nvim-config.git
# ::: :/.claude/hooks/lib/tools.sh
#
#

# Sourced by every hook under `.claude/hooks/`, and named by the skills
# under `.claude/skills/` as the way to reach this repository's pinned
# toolchain from a Claude Code Bash call.
#
# It exists because mise is not activated in that shell. `ts_query_ls` is
# reachable no other way, so `.husky/pre-commit`'s `lintfmt_query` takes
# its `cmd_exist ts_query_ls || return 0` branch and a commit made from a
# tool call formats and lints no `.scm` file at all, silently; the
# `Queries` CI job is the first thing that notices. `luafmt`,
# `emmylua_check` and `emmylua_doc_cli` do resolve, but to
# `~/.local/share/cargo/bin` rather than the pin, which is the shadowing
# hazard `.claude/CLAUDE.md` describes under Toolchain.
#
# Two things established by probe rather than reasoned about:
#
#   - `mise exec` must not be used here. `mise.toml` pins the editor
#     toolchain beside the gates, so `mise exec -- ts_query_ls --version`
#     starts installing all 22 tools before it answers. `bin-paths` and
#     `which` read what is already installed and never reach the network.
#
#   - `selene` is the one tool `mise_path` does not redirect: its install
#     directory is not among the paths `mise bin-paths` prints, so the
#     copy found stays whatever the ambient PATH holds. That copy agrees
#     with the pin today by luck. Use `mise which selene` where the exact
#     version matters.
#
# Every function returns 0 on a machine with no mise, since a hook that
# fails there would block work rather than protect it. `require_tools` is
# the deliberate exception: a missing tool is exactly what it reports.


# Prefix PATH with mise's pinned install directories. Idempotent in
# effect rather than by guard: a second prefix changes no resolution.
mise_path() {
    command -v mise >/dev/null 2>&1 || return 0

    _bin_paths=$(mise bin-paths 2>/dev/null | tr '\n' ':')
    if [ -n "$_bin_paths" ]; then
        PATH="${_bin_paths}${PATH}"
        export PATH
    fi

    unset _bin_paths
    return 0
}


# Print every missing command rather than stopping at the first, matching
# `cmd_exist` in `.husky/pre-commit`: a caller told about one absent tool
# fixes it and is told about the next, which is three round trips where
# one would do. Prints to stdout; returns 1 when anything is missing.
require_tools() {
    _missing=''

    for _cmd in "$@"; do
        command -v "$_cmd" >/dev/null 2>&1 || _missing="${_missing}${_cmd} "
    done

    if [ -n "$_missing" ]; then
        printf '%s' "${_missing% }"
        unset _missing _cmd
        return 1
    fi

    unset _missing _cmd
    return 0
}


# The gate binaries `.husky/pre-commit` runs, in the order it runs them.
# `npx` is deliberately absent: prettier is an npm devDependency rather
# than a mise pin, so its absence is a broken `npm ci` and not a broken
# toolchain, and it would report differently.
GATE_TOOLS='selene luafmt tombi ts_query_ls nvim lua-language-server'
