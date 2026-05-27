# Rebuilding a release locally

## Requirements

- Linux (Ubuntu 22.04+ or Debian 12+ recommended). `dpkg-buildpackage` is Linux-only.
- Go >= 1.26.1 (the version pinned by the current `UPSTREAM_VERSION`).
- System packages: `build-essential libre2-dev debhelper dpkg-dev devscripts`.
- ~3 GB free disk space for the upstream clone + build artifacts.

Install deps on Debian/Ubuntu:

```
sudo apt update
sudo apt install -y build-essential libre2-dev debhelper dpkg-dev devscripts
```

Verify Go version:

```
go version
# should be 1.26.1 or newer
```

## Build steps

From the `release/build` branch root:

```
./scripts/make-release.sh
```

This produces:

```
build-output/crowdsec_<VERSION>-1_amd64.deb
build-output/crowdsec_<VERSION>-1_amd64.changes
build-output/crowdsec_<VERSION>-1_amd64.buildinfo
```

## Validating the produced .deb

On a clean Debian/Ubuntu VM (don't use your dev machine — installing crowdsec writes to
/etc, /var, /usr):

```
sudo dpkg -i crowdsec_*.deb
sudo systemctl status crowdsec
cscli version
cscli features list | grep disable_allowlist_ingestion
```

Expected: `cscli version` shows the fork version; `features list` shows the fflag is
registered (as `false` by default — enable it via `cscli features enable
disable_allowlist_ingestion` or in feature config).

## macOS workaround

Native build is not possible on macOS. Options:

1. Use a Linux VM (UTM, Multipass, VirtualBox).
2. Use a Docker container:

   ```
   docker run --rm -it -v "$PWD":/work -w /work debian:12 bash
   # inside container:
   apt update
   apt install -y curl build-essential libre2-dev debhelper dpkg-dev devscripts git
   curl -L https://go.dev/dl/go1.26.1.linux-amd64.tar.gz | tar -C /usr/local -xz
   export PATH=/usr/local/go/bin:$PATH
   ./scripts/make-release.sh
   ```

3. Defer to CI (push a `-rc<N>` tag, see README).