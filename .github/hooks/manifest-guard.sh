#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation

# Decides whether a language's root-level tooling applies to this checkout.
#
# Usage: manifest-guard.sh <manifest> <source-pathspec>...
#   GUARD_EXCLUDE  optional extended regex of source paths to ignore
#
# Exit codes:
#   3  a root manifest is tracked; the caller should run its tool
#   0  the language is absent, or every tracked source lives under a
#      manifest in a subdirectory, so the root-level hook is inert
#   1  tracked sources exist that no tracked manifest covers
#
# Every test is against the git index rather than the filesystem. A
# pre-commit hook validates what is being committed, so an untracked
# manifest sitting on disk must not satisfy it: a commit carrying sources
# but not their manifest would otherwise pass locally and land a tree
# nobody else can build.
#
# Coverage is checked per source file rather than by asking whether any
# nested manifest exists anywhere. A repository can hold both a nested
# module and sources outside it, and treating the nested manifest as
# blanket permission would let deletion of the root manifest pass while
# those orphaned sources went unlinted.

set -eu

if [ "$#" -lt 2 ]; then
    echo "usage: manifest-guard.sh <manifest> <source-pathspec>..." >&2
    exit 2
fi

manifest=$1
shift

# A tracked root manifest means the root tooling applies.
if git ls-files -- "$manifest" | grep -q .; then
    exit 3
fi

sources=$(git ls-files -- "$@")
if [ -n "${GUARD_EXCLUDE:-}" ]; then
    sources=$(printf '%s\n' "$sources" | grep -vE "$GUARD_EXCLUDE" || true)
fi

# No sources of this language: genuinely not that kind of project.
[ -n "$sources" ] || exit 0

# Directories holding a tracked manifest below the root.
dirs=$(git ls-files -- "*/$manifest" | sed "s|/$manifest\$||" || true)

# The first tracked source not sitting under one of those directories.
orphan=$(printf '%s\n' "$sources" | awk -v dirs="$dirs" '
    BEGIN { n = split(dirs, d, "\n") }
    {
        for (i = 1; i <= n; i++)
            if (d[i] != "" && index($0, d[i] "/") == 1)
                next
        print
        exit
    }')

if [ -n "$orphan" ]; then
    echo "no tracked $manifest covers $orphan - restore or stage $manifest" >&2
    exit 1
fi

exit 0
