# Kubebar Handoff

## Current State

- Plan: `docs/plans/2026-06-02-001-ci-release-build-version-sync-plan.md`
- Status: complete
- Completed steps: U1 `Release builds carry synchronized app version metadata.`
- Latest review: pass

## Verification

- `./scripts/test-release-build-version.sh`
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
- `git diff --check`

## Notes

- Release builds now keep `MARKETING_VERSION` equal to the selected release
  version.
- `CURRENT_PROJECT_VERSION` is no longer fixed at `1`; it resolves from an
  explicit second script argument, then `BUILD_NUMBER`, then
  `git rev-list --count HEAD`.
- `scripts/build-release.sh` validates integer build numbers and verifies the
  built app's `Info.plist` before signing and zipping.
- `project.yml` carries the app target versioning settings so XcodeGen remains
  the durable source.
- The local Swift quality gate now runs release build version tests before the
  Xcode and SwiftPM checks.
- Release docs describe the default build-number behavior and override paths.
- No signing, notarization, Sparkle, Homebrew, or runtime version UI behavior
  was added.
- No known blockers.

## Compaction Handoff

- Active plan: `docs/plans/2026-06-02-001-ci-release-build-version-sync-plan.md`
- Active step: none; U1 is closed.
- Priority files:
  - `scripts/build-release.sh`
  - `scripts/test-release-build-version.sh`
  - `scripts/swift-quality-gate.sh`
  - `project.yml`
  - `docs/RELEASING.md`
- Uncommitted work summary: release build version sync implementation, script
  tests, quality gate wiring, release docs, context/spec/plan, workflow state,
  and handoff update are uncommitted.
- Session decisions: marketing version remains the release version; build
  version defaults to git commit count; explicit argument beats
  `BUILD_NUMBER`; app bundle metadata is verified before packaging.
- Next boundary skill: optional `imm-compounder` for reusable learning capture.
