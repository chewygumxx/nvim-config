#!/usr/bin/env python3
# vim:set expandtab shiftwidth=4 filetype=python:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/nvim-config.git
# ::: :/.github/scripts/tool_version.py
#
#

"""Print the version `mise.toml` pins for a tool.

`mise.toml` is the single place this repository names a tool version, so the
workflows have to read it rather than restate it. This exists because that
read is needed in five places and a regex over TOML is the wrong way to do
it: a `[tools]` entry is either a bare version string or a table carrying
`matching` alongside `version`, and the keys themselves contain the `:` and
`/` that make them awkward regex subjects.

Two call shapes, because the workflows need both:

    tool_version.py 'github:neovim/neovim'
        Prints the version alone, for `$(...)` capture.

    tool_version.py SELENE_VERSION=github:Kampfkarren/selene ...
        Prints `NAME=version` per argument, for appending straight to
        `$GITHUB_ENV`.

Fails loudly on an unknown tool. A workflow that silently got an empty
version would fall back to whatever the runner happened to have, which is
the situation `mise.toml` exists to end.
"""

import sys
import tomllib
from pathlib import Path


def versions(config: Path) -> dict[str, str]:
    """Map every `[tools]` key to its pinned version."""
    with config.open("rb") as handle:
        tools = tomllib.load(handle).get("tools", {})

    resolved = {}
    for key, spec in tools.items():
        # A table entry carries `matching` (which asset of a multi-binary
        # release to take) beside the version; a bare entry is the version.
        version = spec.get("version") if isinstance(spec, dict) else spec
        if isinstance(version, str):
            resolved[key] = version
    return resolved


def main(argv: list[str]) -> int:
    if not argv:
        print(f"usage: {Path(sys.argv[0]).name} [NAME=]TOOL...", file=sys.stderr)
        return 2

    config = Path(__file__).resolve().parents[2] / "mise.toml"
    if not config.is_file():
        print(f"{config}: not found", file=sys.stderr)
        return 1

    pinned = versions(config)

    lines = []
    for argument in argv:
        name, _, tool = argument.partition("=")
        if not tool:
            name, tool = "", name

        if tool not in pinned:
            known = ", ".join(sorted(pinned))
            print(
                f"{config.name}: no [tools] entry for {tool!r}\nknown: {known}",
                file=sys.stderr,
            )
            return 1

        lines.append(f"{name}={pinned[tool]}" if name else pinned[tool])

    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
