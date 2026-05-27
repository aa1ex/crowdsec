# Adding a new patch

## Workflow

1. **Develop the change** in a regular crowdsec clone, on top of the relevant upstream tag:

   ```
   git clone https://github.com/crowdsecurity/crowdsec.git /tmp/dev-clone
   cd /tmp/dev-clone
   git checkout v1.7.8
   # make changes
   git commit -am "feature: short description"
   ```

2. **Test locally** with a regular crowdsec build to ensure the change works:

   ```
   make build BUILD_STATIC=1
   ./cmd/crowdsec/crowdsec --version
   # run unit tests if relevant
   ```

3. **Export the commit as a patch file**:

   ```
   git format-patch -1 HEAD --stdout > \
       /path/to/aa1ex-fork/patches/00NN-short-description.patch
   ```

   Choose `NN` as the next free number in `patches/series`.

4. **Add to series file**:

   Edit `patches/series` and append the new patch filename at the end (apply order matters
   if patches touch the same files).

5. **Verify the series applies cleanly**:

   ```
   cd /path/to/aa1ex-fork
   rm -rf build-work
   ./scripts/apply-patches.sh build-work
   ```

6. **Run local dry-run build** (Linux only):

   ```
   ./scripts/make-release.sh
   ```

7. **Commit and push**:

   ```
   git add patches/series patches/00NN-*.patch
   git commit -m "release/build: add patch 00NN <description>"
   git push
   ```

8. **Cut a release** when ready (see README).

## Tips

- Keep each patch single-purpose. Easier to review, easier to drop if it becomes obsolete.
- Patches should target upstream code paths that are stable. If a patch touches a file that
  changes often upstream, expect to refresh it on every upstream bump.
- If a patch becomes obsolete (upstream merges equivalent fix), remove it from `series` and
  delete the `.patch` file.

## Refreshing patches after manual edits

If you `apply-patches.sh` into `build-work/`, make manual commits there, and want to push
those back into the patch series:

```
./scripts/refresh-patches.sh
git diff patches/   # review changes
```

This regenerates all `.patch` files in `patches/` from the commits in `build-work/`.