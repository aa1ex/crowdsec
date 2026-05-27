# Bumping the upstream version

When upstream crowdsec releases a new version (e.g. `v1.7.9`), use this workflow to move
the fork's pinned upstream pointer forward.

## Happy path (no patch conflicts)

1. Run the bump script:

   ```
   ./scripts/bump-upstream.sh v1.7.9
   ```

   This updates `UPSTREAM_VERSION` and `FORK_VERSION`, then attempts to apply the series.

2. If the script succeeds — patches still apply cleanly to the new upstream.

3. Run a local dry-build (Linux):

   ```
   ./scripts/make-release.sh
   ```

4. If green, commit and tag:

   ```
   git add UPSTREAM_VERSION FORK_VERSION
   git commit -m "release/build: bump upstream to v1.7.9"
   git push
   git tag v1.7.9-aa1ex.1 -m "fork release 1 of v1.7.9"
   git push origin v1.7.9-aa1ex.1
   ```

## Conflict path (one or more patches don't apply)

1. The bump script will leave `build-work/` in a state showing the conflict.

2. Investigate the conflict in `build-work/`:

   ```
   cd build-work
   # The apply-patches.sh script aborts on first conflict; the conflicting patch
   # will have created .rej files or partial application. Inspect:
   git status
   find . -name '*.rej'
   ```

3. Resolve the conflict manually. Two approaches:

   **A. Interactive resolution via cherry-pick-style:**

   ```
   cd build-work
   git apply --reject /path/to/aa1ex-fork/patches/00NN-failing.patch  # see what failed
   # Edit .rej files into the source manually
   git add <fixed-files>
   git commit -m "manual resolution for new upstream"
   ```

   Then re-export:

   ```
   cd /path/to/aa1ex-fork
   ./scripts/refresh-patches.sh
   ```

   **B. Re-author the patch from scratch:**

   If the upstream code has changed enough that the patch needs rewriting:

   ```
   cd build-work
   # Reset to clean upstream
   git reset --hard
   # Manually port the change concept
   git commit -am "ported patch for new upstream"
   ./scripts/refresh-patches.sh  # from harness dir
   ```

4. Once `apply-patches.sh build-work` succeeds, follow the happy path from step 3.

## When to keep FORK_VERSION

If a bump fails and requires significant patch rework, it's still a `FORK_VERSION=1`
because it's the first release of the fork against the new upstream. Don't increment
unless you've already released `<upstream>-aa1ex.1` and need a second iteration on the
same upstream.