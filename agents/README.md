# Agent notes: bitmark-releases (public)

Owner rules, repo map, decisions and roadmap are in the site repo's `agents/` (`bitmark/agents/README.md`). This repo is **only CI**; never put source code, keystores or commit messages of the private repo here (logs and releases are public).

## What it does
`.github/workflows/release.yml` (triggers: 6-hour schedule, manual *Run workflow* with `force`, `repository_dispatch: source-updated`): clones the private `bitmark-android` with a read-only token, plans (is the source commit already released? next version), builds `:app:exportRelease :desktop:exportDesktop` with the signing key, and publishes release `v<x.y.z>` with fixed asset names: `bitmark.apk`, `bitmark-desktop.tar.gz`, `bitmark-desktop.zip`, `release.json`, `SHA256SUMS`.

## Configuration (Settings -> Secrets and variables -> Actions)
- Secrets: `SOURCE_TOKEN` (read-only on the source), `BITMARK_KEYSTORE_B64`, `BITMARK_KEYSTORE_PASSWORD`, `BITMARK_KEY_ALIAS`, `BITMARK_KEY_PASSWORD`.
- Variables: `SOURCE_GIT_URL` (Codeberg or the GitHub mirror, https), optional `SOURCE_BRANCH` (default `master`), `SOURCE_USER` (default `git`).
- Optional instant trigger: the source's GitHub mirror runs `notify-releases.yml` with `RELEASES_DISPATCH_TOKEN` + `RELEASES_REPO` (README step 5).

## Versioning (`scripts/version.sh`)
Run inside the source clone with the last version and its source sha: `type!:`/`BREAKING CHANGE` -> major, `feat:` -> minor, anything else (also non-conventional commits) -> patch. No previous release -> `1.0.0`. `versionCode = major*1000000 + minor*1000 + patch`. The release notes' first line `source: <sha>` is the state that tells the next run what is released; never edit it.

## Gotchas learned
- `android-actions/setup-android@v3` failed on package `tools`; the runner already has the SDK, so the workflow only accepts licences.
- A source checkout without its root `build.gradle.kts` makes `exportAll` "not found"; the workflow checks the Gradle files and names the missing one.
- Scheduled workflows pause after 60 days without repository activity: use *Run workflow*.
- Unit tests run with `continue-on-error`; remove that line once the suite is green.
