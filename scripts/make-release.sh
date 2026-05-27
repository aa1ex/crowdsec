#!/usr/bin/env bash
# make-release.sh — local dry-run of the full release build
#
# Usage: ./scripts/make-release.sh
#
# Performs: apply patches -> build binaries -> build .deb -> smoke check.
# Produces .deb in ./build-output/
#
# Requires installed: go (>= 1.26.1), make (>= 4.1), libre2-dev, build-essential,
#                     debhelper, dpkg-dev
#
# NOTE: dpkg-buildpackage is Linux-only. On macOS this script will fail at
#       the package build step. Use a Linux VM, Docker container, or rely on CI.

set -euo pipefail

HARNESS_DIR=$(cd "$(dirname "$0")/.." && pwd)
WORK_DIR="$HARNESS_DIR/build-work"
OUTPUT_DIR="$HARNESS_DIR/build-output"

UPSTREAM_TAG=$(sed -n '1p' "$HARNESS_DIR/UPSTREAM_VERSION")
FORK_VERSION=$(cat "$HARNESS_DIR/FORK_VERSION")
# Strip leading 'v' from tag for Debian version compatibility
UPSTREAM_BASE=${UPSTREAM_TAG#v}
FULL_VERSION="${UPSTREAM_BASE}-aa1ex.${FORK_VERSION}"

echo "==> Fork release ${FULL_VERSION} (upstream ${UPSTREAM_TAG})"

rm -rf "$WORK_DIR" "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "==> Apply patches"
"$HARNESS_DIR/scripts/apply-patches.sh" "$WORK_DIR"

echo "==> Build binaries (BUILD_STATIC=1)"
make -C "$WORK_DIR" build BUILD_STATIC=1 BUILD_VERSION="v${FULL_VERSION}-linux" BUILD_TAG="aa1ex"

echo "==> Symlink debian/ -> build/debian/ for dpkg-buildpackage"
cd "$WORK_DIR"
ln -sf build/debian debian

echo "==> Set Debian package version"
DEBEMAIL="aa1ex-fork@local" DEBFULLNAME="aa1ex fork" \
    dch --controlmaint -v "${FULL_VERSION}-1" --distribution stable --force-distribution \
    --changelog build/debian/changelog \
    "Fork release ${FULL_VERSION} based on upstream ${UPSTREAM_TAG}"

echo "==> Build .deb"
dpkg-buildpackage -b -uc -us

echo "==> Collect artifacts"
mv "../crowdsec_${FULL_VERSION}-1_amd64.deb" "$OUTPUT_DIR/"
# Also capture any other generated files for inspection
mv "../crowdsec_${FULL_VERSION}-1_amd64.changes" "$OUTPUT_DIR/" 2>/dev/null || true
mv "../crowdsec_${FULL_VERSION}-1_amd64.buildinfo" "$OUTPUT_DIR/" 2>/dev/null || true

echo "==> Smoke check binary version"
BUILT_VERSION=$("$WORK_DIR/cmd/crowdsec/crowdsec" --version 2>&1 | head -1 || true)
echo "    binary reports: $BUILT_VERSION"
if ! echo "$BUILT_VERSION" | grep -q "${FULL_VERSION}"; then
    echo "ERROR: binary version string does not contain ${FULL_VERSION}" >&2
    exit 1
fi

echo "==> Smoke check .deb metadata"
dpkg-deb --info "$OUTPUT_DIR/crowdsec_${FULL_VERSION}-1_amd64.deb" | head -20
dpkg-deb --contents "$OUTPUT_DIR/crowdsec_${FULL_VERSION}-1_amd64.deb" | head -10

echo "==> DONE. Artifact: $OUTPUT_DIR/crowdsec_${FULL_VERSION}-1_amd64.deb"