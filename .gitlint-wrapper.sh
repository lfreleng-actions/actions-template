#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation

# Gitlint wrapper script for use with pre-commit
# Handles different commit range detection for local vs CI environments

set -euo pipefail

# Function to get the default branch
get_default_branch() {
    # Try to detect the default branch
    for branch in main master develop; do
        if git rev-parse --verify "origin/${branch}" >/dev/null 2>&1; then
            echo "origin/${branch}"
            return 0
        fi
    done
    # Fallback
    echo "origin/HEAD"
}

# Detect if we're running in GitHub Actions CI
if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    # Running in GitHub Actions CI
    if [[ -n "${GITHUB_BASE_REF:-}" ]]; then
        # Pull request context - check commits from base to HEAD
        BASE_SHA="${GITHUB_BASE_SHA:-origin/${GITHUB_BASE_REF}}"
        echo "Running gitlint in GitHub Actions for PR commits: ${BASE_SHA}..HEAD"
        gitlint --commits "${BASE_SHA}..HEAD"
    else
        # Push to branch - check the pushed commits
        if [[ -n "${GITHUB_EVENT_BEFORE:-}" ]] && [[ "${GITHUB_EVENT_BEFORE}" != "0000000000000000000000000000000000000000" ]]; then
            echo "Running gitlint in GitHub Actions for pushed commits: ${GITHUB_EVENT_BEFORE}..HEAD"
            gitlint --commits "${GITHUB_EVENT_BEFORE}..HEAD"
        else
            # Fallback: check just the last commit
            echo "Running gitlint in GitHub Actions for last commit"
            gitlint --commits HEAD
        fi
    fi
elif [[ -n "${PRE_COMMIT_FROM_REF:-}" ]] && [[ -n "${PRE_COMMIT_TO_REF:-}" ]]; then
    # pre-commit.ci sets these environment variables
    echo "Running gitlint in pre-commit.ci for commits: ${PRE_COMMIT_FROM_REF}..${PRE_COMMIT_TO_REF}"
    gitlint --commits "${PRE_COMMIT_FROM_REF}..${PRE_COMMIT_TO_REF}"
elif [[ -n "${CI:-}" ]]; then
    # Running in some other CI system
    # Try to determine the base branch and check all commits from there
    BASE=$(get_default_branch)

    # Find merge base if possible
    MERGE_BASE=$(git merge-base HEAD "${BASE}" 2>/dev/null || echo "${BASE}")

    echo "Running gitlint in CI for commits: ${MERGE_BASE}..HEAD"
    gitlint --commits "${MERGE_BASE}..HEAD"
else
    # Running locally during commit-msg hook
    # pre-commit passes the commit message file as the first argument
    if [[ $# -gt 0 ]] && [[ -f "$1" ]]; then
        # Commit message file passed - this is the commit-msg hook
        echo "Running gitlint locally for commit message"
        gitlint --msg-filename "$1"
    else
        # No file passed - this is likely `pre-commit run -a` or similar
        # Only check commits on the current branch that aren't on origin

        # Find commits that exist locally but not on any remote branch
        BASE=$(get_default_branch)

        # Get the merge base with the default branch
        if git rev-parse --verify "${BASE}" >/dev/null 2>&1; then
            MERGE_BASE=$(git merge-base HEAD "${BASE}" 2>/dev/null || echo "${BASE}")
            echo "Running gitlint locally for commits since ${MERGE_BASE}"
            gitlint --commits "${MERGE_BASE}..HEAD"
        else
            # Fallback: just check the last commit
            echo "Running gitlint locally for last commit"
            gitlint --commits HEAD
        fi
    fi
fi
