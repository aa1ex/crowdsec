#!/usr/bin/env bash
# bump-upstream.sh — bump UPSTREAM_VERSION, attempt to apply series, report status
#
# Usage: ./scripts/bump-upstream.sh <new-tag>
#   new-tag: e.g. v1.7.9

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <new-tag>" >&2
    exit 2
fi

NEW_TAG=$1
HARNESS_DIR=$(cd "$(dirname "$0")/.." && pwd)

echo "==> Resolving $NEW_TAG to commit SHA"
NEW_SHA=$(git ls-remote https://github.com/crowdsecurity/crowdsec.git "refs/tags/$NEW_TAG" | awk '{print $1}')
if [[ -z "$NEW_SHA" ]]; then
    echo "ERROR: tag $NEW_TAG not found in upstream" >&2
    exit 1
fi
echo "    $NEW_TAG = $NEW_SHA"

echo "==> Updating UPSTREAM_VERSION"
cat > "$HARNESS_DIR/UPSTREAM_VERSION" <<EOF
$NEW_TAG
$NEW_SHA
EOF

echo "==> Resetting FORK_VERSION to 1"
echo "1" > "$HARNESS_DIR/FORK_VERSION"

echo "==> Test apply against $NEW_TAG"
rm -rf "$HARNESS_DIR/build-work"
if "$HARNESS_DIR/scripts/apply-patches.sh" "$HARNESS_DIR/build-work"; then
    echo "==> SUCCESS: patches apply cleanly to $NEW_TAG"
    echo "    Next: ./scripts/make-release.sh to build locally,"
    echo "          git commit + tag v${NEW_TAG#v}-aa1ex.1 to release"
else
    echo "==> FAILURE: patch series did not apply cleanly to $NEW_TAG" >&2
    echo "    Manual resolution needed:"
    echo "      1. cd $HARNESS_DIR/build-work (if it exists)" >&2
    echo "      2. Resolve conflicts, commit fixes" >&2
    echo "      3. ./scripts/refresh-patches.sh to regenerate patches/" >&2
    echo "      4. git diff patches/ to review" >&2
    exit 1
fi