#!/usr/bin/env bash
# apply-patches.sh — clone upstream crowdsec at pinned version, apply patch series
#
# Usage: ./scripts/apply-patches.sh <target-dir>
#   target-dir: where to create the prepared source tree (will be created if missing,
#               must be empty if exists)
#
# Reads UPSTREAM_VERSION (tag + SHA) and patches/series from the current directory.
# Clones upstream into target-dir, checks out the pinned commit, applies patches in order.

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <target-dir>" >&2
    exit 2
fi

TARGET_DIR=$1
HARNESS_DIR=$(cd "$(dirname "$0")/.." && pwd)

if [[ ! -f "$HARNESS_DIR/UPSTREAM_VERSION" ]]; then
    echo "ERROR: UPSTREAM_VERSION not found in $HARNESS_DIR" >&2
    exit 1
fi

if [[ ! -f "$HARNESS_DIR/patches/series" ]]; then
    echo "ERROR: patches/series not found in $HARNESS_DIR" >&2
    exit 1
fi

UPSTREAM_TAG=$(sed -n '1p' "$HARNESS_DIR/UPSTREAM_VERSION")
UPSTREAM_SHA=$(sed -n '2p' "$HARNESS_DIR/UPSTREAM_VERSION")

if [[ -z "$UPSTREAM_TAG" || -z "$UPSTREAM_SHA" ]]; then
    echo "ERROR: UPSTREAM_VERSION must contain tag on line 1, SHA on line 2" >&2
    exit 1
fi

echo "==> Upstream tag: $UPSTREAM_TAG (commit $UPSTREAM_SHA)"

if [[ -e "$TARGET_DIR" ]]; then
    if [[ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]]; then
        echo "ERROR: target dir $TARGET_DIR is not empty" >&2
        exit 1
    fi
else
    mkdir -p "$TARGET_DIR"
fi

echo "==> Cloning upstream into $TARGET_DIR"
git clone --depth 50 --branch "$UPSTREAM_TAG" \
    https://github.com/crowdsecurity/crowdsec.git "$TARGET_DIR"

echo "==> Verifying pinned commit"
ACTUAL_SHA=$(git -C "$TARGET_DIR" rev-parse HEAD)
if [[ "$ACTUAL_SHA" != "$UPSTREAM_SHA" ]]; then
    echo "ERROR: pinned SHA $UPSTREAM_SHA does not match HEAD $ACTUAL_SHA" >&2
    echo "       (tag $UPSTREAM_TAG may have been moved upstream — investigate)" >&2
    exit 1
fi

echo "==> Configuring git identity for am (required for commit creation)"
git -C "$TARGET_DIR" config user.email "aa1ex-fork-build@local"
git -C "$TARGET_DIR" config user.name "aa1ex fork build"

echo "==> Applying patch series via git am (preserves commits for refresh workflow)"
while IFS= read -r patch_file || [[ -n "$patch_file" ]]; do
    [[ -z "$patch_file" || "$patch_file" == \#* ]] && continue
    full_path="$HARNESS_DIR/patches/$patch_file"
    if [[ ! -f "$full_path" ]]; then
        echo "ERROR: patch $patch_file listed in series but not found" >&2
        exit 1
    fi
    echo "    applying $patch_file"
    if ! git -C "$TARGET_DIR" am --whitespace=nowarn "$full_path"; then
        echo "ERROR: failed to apply $patch_file" >&2
        echo "       target dir state preserved at $TARGET_DIR for manual inspection" >&2
        echo "       run: cd $TARGET_DIR && git am --abort  (to clean up)" >&2
        exit 1
    fi
done < "$HARNESS_DIR/patches/series"

echo "==> All patches applied successfully (as commits)"