#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation

# Decides whether a language's root-level tooling applies to this checkout.
#
# Usage: manifest-guard.sh <manifest> <source-pathspec>...
#   GUARD_EXCLUDE  optional extended regex of source paths to ignore
#
# Exit codes:
#   3  a root manifest is tracked and owns at least one source: run the tool
#   4  a root manifest is tracked but owns no source. Tools that only touch
#      the manifest, or that are no-ops without sources, should still run;
#      analysis tools must skip, because `go vet ./...` exits 1 and
#      `golangci-lint run` exits 5 on a module with nothing to analyse, which
#      would block the very commit that removes the last Go file.
#   0  the language is absent, or every tracked source lives under a manifest
#      in a subdirectory, so the root-level hook is inert
#   1  tracked sources exist that no tracked manifest covers
#
# Every test is against the git index rather than the filesystem. A
# pre-commit hook validates what is being committed, so an untracked
# manifest sitting on disk must not satisfy it: a commit carrying sources
# but not their manifest would otherwise pass locally and land a tree
# nobody else can build.
#
# One computation serves both questions. "Unnested" below is the set of
# tracked sources that do not sit under a manifest in a subdirectory. When a
# root manifest is tracked those are the sources it owns; when none is
# tracked they are sources no manifest covers at all. Deciding coverage per
# file, rather than asking whether a nested manifest exists anywhere, is what
# stops a nested module masking deletion of the root manifest while sources
# outside it go unlinted.

set -eu

if [ "$#" -lt 2 ]; then
    echo "usage: manifest-guard.sh <manifest> <source-pathspec>..." >&2
    exit 2
fi

manifest=$1
shift

root_tracked=0
if git ls-files -- "$manifest" | grep -q .; then
    root_tracked=1
fi

sources=$(git ls-files -- "$@")
if [ -n "${GUARD_EXCLUDE:-}" ]; then
    sources=$(printf '%s\n' "$sources" | grep -vE "$GUARD_EXCLUDE" || true)
fi

# Directories holding a tracked manifest below the root.
dirs=$(git ls-files -- "*/$manifest" | sed "s|/$manifest\$||" || true)

# The first tracked source not sitting under one of those directories.
unnested=""
if [ -n "$sources" ]; then
    unnested=$(printf '%s\n' "$sources" | awk -v dirs="$dirs" '
        BEGIN { n = split(dirs, d, "\n") }
        {
            for (i = 1; i <= n; i++)
                if (d[i] != "" && index($0, d[i] "/") == 1)
                    next
            print
            exit
        }')
fi

if [ "$root_tracked" = 1 ]; then
    [ -n "$unnested" ] && exit 3
    exit 4
fi

# No root manifest from here on.
[ -n "$sources" ] || exit 0

if [ -n "$unnested" ]; then
    echo "no tracked $manifest covers $unnested - restore or stage $manifest" >&2
    exit 1
fi

exit 0
