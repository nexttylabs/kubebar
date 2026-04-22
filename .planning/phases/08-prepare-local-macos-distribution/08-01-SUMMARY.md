---
phase: 08-prepare-local-macos-distribution
plan: "01"
subsystem: local-distribution
tags: [macos, install, xcode, scripts]

requires: []
provides:
  - Local installer for the Xcode-built Kubebar.app bundle
  - Bundle metadata and asset verification before and after install
  - Default install path at ~/Applications/Kubebar.app
affects: [local-install, build-verification]

tech-stack:
  added: []
  patterns:
    - Reuse the existing Swift quality gate before install
    - Verify copied .app bundles with Info.plist and resource checks
    - Replace only the installed Kubebar.app bundle

key-files:
  created:
    - scripts/install-local.sh
    - .planning/phases/08-prepare-local-macos-distribution/08-01-SUMMARY.md
  modified: []

key-decisions:
  - "Debug remains the quality-gate configuration because Release tests cannot import @testable modules."
  - "Release remains the default installed app configuration."
  - "The installer quits only com.nextty.kubebar and replaces only the copied app bundle."

requirements-completed: [ISSUE-8-AC1, ISSUE-8-AC3, ISSUE-8-AC4]

duration: 23 min
completed: 2026-04-22
---

# Phase 08 Plan 01: Local Install Script Summary

**Kubebar can now be built, checked, verified, and copied as a local macOS app bundle without opening Xcode.**

## Performance

- **Duration:** 23 min
- **Started:** 2026-04-22T02:32:00Z
- **Completed:** 2026-04-22T02:55:00Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Added `scripts/install-local.sh` with the locked app name, bundle id, Release install output, and default destination at `~/Applications`.
- Added bundle verification for `CFBundleIdentifier`, `CFBundleIconFile`, `LSUIElement`, `AppIcon.icns`, `Assets.car`, and the app executable.
- Added targeted install/update behavior that quits only `com.nextty.kubebar`, replaces only the copied `Kubebar.app`, and leaves Application Support config untouched.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create installer skeleton** - `c842051` (feat)
2. **Task 2: Verify built app bundle** - `faddbae` (feat)
3. **Task 3: Install local app bundle** - `bbca70b` (feat)
4. **Deviation fix: Use Debug quality gate before Release install** - `8a4cce5` (fix)

## Files Created/Modified

- `scripts/install-local.sh` - Builds through the quality gate, creates a Release app bundle, verifies the built and installed bundles, and copies to the local install destination.
- `.planning/phases/08-prepare-local-macos-distribution/08-01-SUMMARY.md` - Records plan results.

## Decisions Made

- Kept `XCODE_CONFIGURATION` as the Release install output setting.
- Added `XCODE_QUALITY_GATE_CONFIGURATION`, defaulting to Debug, so `@testable import` tests run under a valid configuration before the Release bundle is built.
- Used `ditto` for app bundle copying and `PlistBuddy` for bundle proof.

## Deviations from Plan

### Auto-fixed Issues

**1. Release quality-gate tests cannot import @testable modules**
- **Found during:** Full installer verification.
- **Issue:** Running `./scripts/install-local.sh` with `XCODE_CONFIGURATION=Release` caused Xcode tests to fail because `KubebarCore` was built without `-enable-testing`.
- **Fix:** The installer now runs the existing quality gate with Debug by default, then builds the Release app bundle for installation.
- **Files modified:** `scripts/install-local.sh`
- **Verification:** `./scripts/install-local.sh` passed after the fix and installed the Release bundle to `~/Applications/Kubebar.app`.
- **Committed in:** `8a4cce5`

---

**Total deviations:** 1 auto-fixed script issue.
**Impact on plan:** The behavior still satisfies the phase goal: quality checks pass before the app is installed, and the installed product is a Release app bundle.

## Issues Encountered

- Initial full install verification failed in Release test mode because the project uses `@testable import KubebarCore`.

## Verification

- `bash -n scripts/install-local.sh` - passed.
- Script acceptance greps for variables, bundle checks, quality-gate call, install output, targeted quit, and deferred-scope exclusions - passed.
- `./scripts/install-local.sh` - passed.
- `test -d "$HOME/Applications/Kubebar.app"` - passed.
- `/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$HOME/Applications/Kubebar.app/Contents/Info.plist"` - printed `com.nextty.kubebar`.
- `/usr/libexec/PlistBuddy -c "Print :LSUIElement" "$HOME/Applications/Kubebar.app/Contents/Info.plist"` - printed `true`.
- `/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$HOME/Applications/Kubebar.app/Contents/Info.plist"` - printed `AppIcon`.
- Installed bundle contains `Contents/Resources/AppIcon.icns` and `Contents/Resources/Assets.car`.
- Quality gate inside the install run passed with 89 Xcode tests and 89 SwiftPM tests.

## Known Stubs

None.

## Threat Flags

None. The script prints only paths, does not touch Kubernetes credentials, and only replaces the copied app bundle.

## User Setup Required

None.

## Next Phase Readiness

Ready for Phase 08 Plan 02. The local install command exists and has been verified against a real installed app bundle.

## Self-Check: PASSED

- Summary file exists.
- Task commits found: `c842051`, `faddbae`, `bbca70b`, `8a4cce5`.
- Installed app bundle verified at `~/Applications/Kubebar.app`.
