# crowdsec fork build harness

This branch (`release/build`) contains the build infrastructure for a downstream fork of
[crowdsecurity/crowdsec](https://github.com/crowdsecurity/crowdsec) that applies internal
patches and produces a drop-in compatible `.deb` package for linux/amd64.

## What's in this branch

- `UPSTREAM_VERSION` — pinned upstream tag + commit SHA
- `FORK_VERSION` — incremental release counter for the current upstream version
- `patches/series` + `patches/*.patch` — quilt-style patch series applied on top of upstream
- `scripts/` — local helper scripts (apply patches, refresh, bump upstream, dry-run build)
- `.github/workflows/release.yml` — CI that builds .deb on tag push

## What's NOT in this branch

Upstream crowdsec source code. It is cloned on demand into `/tmp/` or `${RUNNER_TEMP}/`.

## How to add a new patch

See [docs/adding-a-patch.md](docs/adding-a-patch.md).

## How to bump upstream version

See [docs/bumping-upstream.md](docs/bumping-upstream.md).

## How to rebuild a release locally

See [docs/rebuilding-locally.md](docs/rebuilding-locally.md).

## How to cut a release

1. Ensure `UPSTREAM_VERSION` is current and `FORK_VERSION` is correct.
2. Commit and push any pending changes.
3. Tag: `git tag v<UPSTREAM>-aa1ex.<FORK> && git push origin v<UPSTREAM>-aa1ex.<FORK>`
4. CI builds the .deb and creates a GitHub Release automatically.

Example: `git tag v1.7.8-aa1ex.1 && git push origin v1.7.8-aa1ex.1`

## Version scheme notes

The version `1.7.8-aa1ex.1` follows Debian package conventions. Per dpkg ordering rules,
this version is `>` upstream `1.7.8` but `<` upstream `1.7.9`. An operator who installs
the fork should `apt-mark hold crowdsec` to prevent inadvertent upgrades to a new upstream
version that would not have the fork's patches.