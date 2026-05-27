#!/usr/bin/env bash
# refresh-patches.sh — re-export commits from build-work back into patches/
#
# Usage: ./scripts/refresh-patches.sh
#
# Assumes build-work/ has been prepared via apply-patches.sh, and the developer
# has added new commits on top with fixes. This script exports all commits since
# the upstream tag back into patches/, renumbered, replacing the existing series.

set -euo pipefail

HARNESS_DIR=$(cd "$(dirname "$0")/.." && pwd)
WORK_DIR="$HARNESS_DIR/build-work"

if [[ ! -d "$WORK_DIR/.git" ]]; then
    echo "ERROR: $WORK_DIR is not a git repo. Run apply-patches.sh first." >&2
    exit 1
fi

UPSTREAM_TAG=$(sed -n '1p' "$HARNESS_DIR/UPSTREAM_VERSION")
UPSTREAM_SHA=$(sed -n '2p' "$HARNESS_DIR/UPSTREAM_VERSION")

echo "==> Exporting commits from $WORK_DIR since $UPSTREAM_TAG ($UPSTREAM_SHA)"

COMMIT_COUNT=$(git -C "$WORK_DIR" rev-list --count "$UPSTREAM_SHA"..HEAD)
if [[ "$COMMIT_COUNT" == "0" ]]; then
    echo "WARN: no commits in $WORK_DIR since upstream; nothing to export" >&2
    exit 0
fi

echo "    will export $COMMIT_COUNT commit(s)"

# Backup existing patches
BACKUP="$HARNESS_DIR/patches.bak.$(date +%s)"
cp -r "$HARNESS_DIR/patches" "$BACKUP"
echo "    backed up old patches to $BACKUP"

# Clear and regenerate
rm -f "$HARNESS_DIR/patches"/*.patch
git -C "$WORK_DIR" format-patch "$UPSTREAM_SHA"..HEAD -o "$HARNESS_DIR/patches/"

# Regenerate series file
ls "$HARNESS_DIR/patches/"*.patch | xargs -n1 basename | sort > "$HARNESS_DIR/patches/series"

echo "==> Patches refreshed. Inspect changes with:"
echo "    git diff -- patches/"
echo "    diff -ru $BACKUP $HARNESS_DIR/patches"