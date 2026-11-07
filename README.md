# BitMark releases

Public download page and build machine for the **BitMark** Android app and Linux desktop app. The source code is private and is **not** in this repository:
a scheduled GitHub Action here clones it with a read-only token, builds and signs it, and publishes the result as a release.

**Latest downloads** (stable links, replace `<owner>`):
- Android: `https://github.com/<owner>/bitmark-releases/releases/latest/download/bitmark.apk`
- Linux (Java 17+): `https://github.com/<owner>/bitmark-releases/releases/latest/download/bitmark-desktop.tar.gz`
- Update info: `.../releases/latest/download/release.json` - checksums: `.../SHA256SUMS`

Linux: `tar xzf bitmark-desktop.tar.gz && cd bitmark-desktop && ./bin/bitmark-desktop` (or `./install.sh`). Ubuntu 22.04: `sudo apt install openjdk-17-jre`.

## How it fits together
```
you -> Codeberg (private source, primary) --push mirror--> GitHub private mirror (optional)
                       ^ cloned with SOURCE_TOKEN every 30 min                |
bitmark-releases (this public repo, Actions) <-- optional repository_dispatch -+
        |  builds + signs, version from the commits  ->  GitHub Release v<x.y.z>  (bitmark.apk, bitmark-desktop.tar.gz/.zip, release.json, SHA256SUMS)
```
The build can read the source straight from Codeberg (default recommendation) or from the GitHub mirror; only `SOURCE_GIT_URL` differs.

## Setup (once)
1. **Create this repo** on GitHub: `bitmark-releases`, **Public**. Push these files (`git init`, `git am` the provided patch or copy the files, `git push`). Settings -> Actions -> General: *Fork pull request workflows* = require approval (the workflow has no pull-request trigger and forks never receive secrets).
2. **Signing secrets** (Settings -> Secrets and variables -> Actions -> *Secrets*): `BITMARK_KEYSTORE_B64` = `base64 -w0 keystore/bitmark-release.jks`, `BITMARK_KEYSTORE_PASSWORD`, `BITMARK_KEY_ALIAS`, `BITMARK_KEY_PASSWORD` (the values in your `keystore.properties`). The key must stay the same for ever, or phones refuse updates. Keep an offline backup.
3. **Where the private source is**: *Variables* tab: `SOURCE_GIT_URL` (e.g. `https://codeberg.org/<you>/bitmark-android.git`, or the GitHub mirror `https://github.com/<you>/bitmark-android.git`), optional `SOURCE_BRANCH` (default `master`) and `SOURCE_USER` (default `git`; Codeberg: your Codeberg user name). Secret `SOURCE_TOKEN`: a **read-only** token. Codeberg: Settings -> Applications -> new token with *repository: read*. GitHub: fine-grained token, only the source repo, *Contents: Read-only*.
4. **First run**: Actions -> *release* -> Run workflow (tick *force*). Expected: clone, plan (`Releasing 1.0.0 ...`), build, publish. Download the APK from the new release and check it installs. Report failures with the failing step's log.
5. **Optional instant trigger**: without it a push is built within 30 minutes (GitHub may delay or, after 60 days without repository activity, pause scheduled runs; *Run workflow* always works). For instant builds the private GitHub mirror runs `notify-releases.yml` (shipped in the source repo): add the secret `RELEASES_DISPATCH_TOKEN` there (fine-grained token on *this* repo, *Contents: Read and write*) and the variable `RELEASES_REPO` = `<owner>/bitmark-releases`.

## Versions
Semantic versioning from the source's commits since the last release (Conventional Commits): `type!:` or a `BREAKING CHANGE` line -> major, `feat:` -> minor, anything else (`fix:`, `docs:`, and commits that do not follow the standard) -> patch. APK and tar share the version. The first release is `1.0.0`. `versionCode` = major\*1000000 + minor\*1000 + patch. The release notes record the source commit (`source: <sha>`); that line is how the next run knows what has been released. Do not edit it.

## Privacy notes
Build logs and release assets are public. The workflow does not print source files or commit messages, and the release notes contain only the source commit hash. Compiler errors would show file names and lines in a failed run. Secrets are masked in logs.
