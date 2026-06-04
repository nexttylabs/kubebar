# Releasing Kubebar

This document outlines the release process for Kubebar. Since the project currently does not use an Apple Developer account, releases are distributed as **Ad-hoc signed** bundles.

## Release Checklist

- [ ] **Finalize Changes**: Ensure all features and fixes for the version are merged.
- [ ] **Generate Draft Changelog**: In GitHub Actions, run
  `Generate Changelog Candidates` with `from_ref` set to the previous release
  tag and `to_ref` set to the target ref. Review and merge the generated PR
  containing `changelog.d/` candidate fragments.
- [ ] **Confirm Changelog Fragments**: Ensure every user-facing PR has a
  release-note-ready fragment in `changelog.d/`, or a clear PR explanation for
  why none is needed.
- [ ] **Prepare Changelog**: In GitHub Actions, run `Release` with
  `mode=prepare`, the target `version`, and `dry_run=false`. Review and merge
  the generated PR containing the finalized `CHANGELOG.md` section.
- [ ] **Dry-run Publish**: In GitHub Actions, run `Release` with
  `mode=publish`, the target `version`, and `dry_run=true` to validate release
  notes, quality gates, and packaging without creating a tag or GitHub Release.
- [ ] **Publish**: Run `Release` again with `mode=publish` and `dry_run=false`.
  GitHub Actions creates the tag, builds `Kubebar.zip`, uploads the artifact,
  and creates the GitHub Release.

## Changelog Workflow

Kubebar uses curated changelog text rather than generated commit summaries.
`CHANGELOG.md` is the final release history; `changelog.d/` is a staging area
for PR-time release notes.

### During PR Work

For user-facing changes, add a fragment:

```text
changelog.d/<short-description>.<type>.md
```

Supported fragment types are documented in `changelog.d/README.md`.

Each fragment should contain one or more short user-facing bullet lines, for
example:

```markdown
- Validate release notes before publishing GitHub Releases.
```

Internal-only changes can skip a fragment when the pull request explains why.
The `Changelog Fragment Check` workflow enforces this: PRs must either include
a `changelog.d/*.md` fragment, check the `Not user-facing` box, or be the
generated release notes PR.

### Preparing Release Notes from GitHub

After the reviewed `changelog.d/` fragments land on `main`, prepare the final
release notes from GitHub:

1. Open GitHub Actions and run `Release`.
2. Set `mode` to `prepare`.
3. Set `version` to the target version, such as `0.3.2`.
4. Leave `release_date` blank to use the workflow date, or enter an explicit
   `YYYY-MM-DD` date.
5. Set `dry_run=true` first if you only want to validate the generated section.
6. Set `dry_run=false` to open or update the release notes pull request.
7. Review and merge the pull request before publishing.

### Local Fallback Before Tagging

Prepare the release changelog:

```bash
./scripts/prepare-changelog-release.sh 0.2.0
```

This creates a finalized `## [0.2.0] - YYYY-MM-DD` section in `CHANGELOG.md`
from pending fragments and removes the merged fragments. Run the quality gate
afterward.

### Drafting Changelog Candidates from GitHub

Release owners can draft changelog fragments without local commands:

1. Open GitHub Actions and run `Generate Changelog Candidates`.
2. Set `from_ref` to the previous release tag, such as `v0.3.1`.
3. Set `to_ref` to the target branch or commit, usually `HEAD` or `main`.
4. Optionally set `output_prefix` to a stable value such as
   `release-v0.3.2`.
5. Review the generated pull request and edit or remove any noisy candidate
   entries before merging it.

The workflow also uploads the generated fragments as an artifact. The pull
request is the normal review path; the artifact is only a fallback.

### Publishing from GitHub

After the release notes PR lands on `main`, publishing is explicit rather than
automatic:

1. Open GitHub Actions and run `Release`.
2. Set `mode` to `publish`.
3. Set `version` to the target version, such as `0.3.2`.
4. Set `dry_run=true` first to validate the finalized notes, run the quality
   gate, build `Kubebar.zip`, and upload the artifact without creating a tag or
   GitHub Release.
5. Set `dry_run=false` when ready to publish.

The publish job reads the finalized `CHANGELOG.md` section, validates the
notes, checks that the matching tag does not already exist, runs the quality
gate, builds `Kubebar.zip`, uploads the artifact, creates the tag, and publishes
the GitHub Release.

The workflow uses the `release` environment. If GitHub environment protection is
enabled for the repository, the publish job will wait for the configured
reviewer approval before it can create tags or releases.

The tag-push path still works as a fallback for maintainers who need to replay
an existing tag.

### Release Version Metadata

Release builds set the app bundle marketing version
(`CFBundleShortVersionString`) from the selected release version, such as
`0.3.2`.

The app bundle build number (`CFBundleVersion`) defaults to
`git rev-list --count HEAD`, so release artifacts do not keep reusing build
number `1`. To override it locally, pass an explicit second argument:

```bash
./scripts/build-release.sh 0.3.2 123
```

CI or scripted release runs can also set `BUILD_NUMBER`:

```bash
BUILD_NUMBER=123 ./scripts/build-release.sh 0.3.2
```

The release script verifies the built app's `Info.plist` before signing and
zipping, and fails if the marketing version or build number does not match the
requested metadata.

### During GitHub Release

The release workflow extracts notes with:

```bash
./scripts/extract-release-notes.sh 0.2.0
```

Publishing fails before the GitHub Release is created when the matching
changelog section is missing, duplicated, empty, or not finalized.

The GitHub Release body is composed from the finalized changelog section plus
the ad-hoc signing installation note below.

## Ad-hoc Signing & Distribution

Without an Apple Developer certificate, the app cannot be notarized. This means macOS will flag it as "unverified" when downloaded.

### Signing Command
During the build process, the app is signed using:
```bash
codesign --force --deep --sign - Kubebar.app
```

### User Guidance for Ad-hoc Apps
When users download the pre-compiled `.zip`, they will encounter Gatekeeper warnings. You **must** include the following instructions in the GitHub Release notes:

> **Note on macOS Security**:
> Kubebar is currently distributed with an Ad-hoc signature. To run it:
> 1. Download and extract the `.zip`.
> 2. Right-click `Kubebar.app` and select **Open**.
> 3. Click **Open** again in the confirmation dialog.
> 4. Alternatively, run `xattr -cr /path/to/Kubebar.app` in your terminal to remove the quarantine flag.

## Future Path: Formal Distribution

The transition to a formal release flow will require:
1. **Apple Developer Account**: For code signing and notarization.
2. **Notarytool Integration**: Automating the submission to Apple's notary service.
3. **Sparkle Appcast**: Setting up an `appcast.xml` for automated in-app updates.
4. **Homebrew Cask**: Creating a formula for `brew install --cask kubebar`.
