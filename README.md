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
                       ^ cloned with SOURCE_TOKEN every 6 h                |
bitmark-releases (this public repo, Actions) <-- optional repository_dispatch -+
        |  builds + signs, version from the commits  ->  GitHub Release v<x.y.z>  (bitmark.apk, bitmark-desktop.tar.gz/.zip, release.json, SHA256SUMS)
```
The build can read the source straight from Codeberg (default recommendation) or from the GitHub mirror; only `SOURCE_GIT_URL` differs.

## Setup (once)
1. **Create this repo** on GitHub: `bitmark-releases`, **Public**. Push these files (`git init`, `git am` the provided patch or copy the files, `git push`). Settings -> Actions -> General: *Fork pull request workflows* = require approval (the workflow has no pull-request trigger and forks never receive secrets).
2. **Signing secrets** (Settings -> Secrets and variables -> Actions -> *Secrets*): `BITMARK_KEYSTORE_B64` = `base64 -w0 keystore/bitmark-release.jks`, `BITMARK_KEYSTORE_PASSWORD`, `BITMARK_KEY_ALIAS`, `BITMARK_KEY_PASSWORD` (the values in your `keystore.properties`). The key must stay the same for ever, or phones refuse updates. Keep an offline backup.
3. **Where the private source is**: *Variables* tab: `SOURCE_GIT_URL` (e.g. `https://codeberg.org/<you>/bitmark-android.git`, or the GitHub mirror `https://github.com/<you>/bitmark-android.git`), optional `SOURCE_BRANCH` (default `master`) and `SOURCE_USER` (default `git`; Codeberg: your Codeberg user name). Secret `SOURCE_TOKEN`: a **read-only** token. Codeberg: Settings -> Applications -> new token with *repository: read*. GitHub: fine-grained token, only the source repo, *Contents: Read-only*.
4. **First run**: Actions -> *release* -> Run workflow (tick *force*). Expected: clone, plan (`Releasing 1.0.0 ...`), build, publish. Download the APK from the new release and check it installs. Report failures with the failing step's log.
5. **Optional: instant builds.** Skip this if waiting up to 6 hours after a push is fine (the poll in step 4 always works; *Run workflow* builds immediately by hand). To build within a minute of a push, the *private GitHub mirror* (`bitmark-android`) tells this repo to start. Flow: push to Codeberg -> mirror to GitHub -> `notify-releases.yml` (already in the source repo) runs there -> it calls this repo's API -> the build starts.
   1. **Create a token** (GitHub -> your profile -> Settings -> Developer settings -> Personal access tokens -> Fine-grained tokens -> Generate new token): name `notify-releases`; *Repository access* -> **Only select repositories** -> **`bitmark-releases` (this public repo, not the private one)**; *Permissions -> Repository permissions -> Contents: Read and write*; longest expiry. Copy the token.
   2. **Store it in the private mirror repo** (`bitmark-android` on GitHub -> Settings -> Secrets and variables -> Actions): *Secrets* tab -> New repository secret `RELEASES_DISPATCH_TOKEN` = the token; *Variables* tab -> New repository variable `RELEASES_REPO` = `<your GitHub user>/bitmark-releases`.
   3. **Test:** push a code change (commits touching only `*.md`, `docs/` or `error-logs/` do not notify). On the mirror's *Actions* tab the run *notify-releases* turns green; here, a *release* run starts with the event `repository_dispatch`. A log line "not set" means the secret or variable is missing; `404` = wrong `RELEASES_REPO` or the token is not scoped to this repo; `403` = *Contents: Read and write* missing; `401` = token expired. If the Codeberg push mirror cannot push `.github/workflows/*`, its GitHub token needs *Workflows: Read and write*.

## Versions
Semantic versioning from the source's commits since the last release (Conventional Commits): `type!:` or a `BREAKING CHANGE` line -> major, `feat:` -> minor, anything else (`fix:`, `docs:`, and commits that do not follow the standard) -> patch. APK and tar share the version. The first release is `1.0.0`. `versionCode` = major\*1000000 + minor\*1000 + patch. The release notes record the source commit (`source: <sha>`); that line is how the next run knows what has been released. Do not edit it.

## Privacy notes
Build logs and release assets are public. The workflow does not print source files or commit messages, and the release notes contain only the source commit hash. Compiler errors would show file names and lines in a failed run. Secrets are masked in logs.
