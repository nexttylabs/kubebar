---
phase: 04-codexbar-inspired-menu-reliability-and-freshness
plan: "01"
subsystem: tooling
tags: [macos, xcode, launch, smoke-test]
requires: []
provides:
  - Local command that builds, tests, launches, and verifies Kubebar
  - More reliable Xcode scheme detection in the quality gate
affects: [local-verification, qa, menu-bar]
tech-stack:
  added: []
  patterns: [visible app smoke test, explicit xcode project selection]
key-files:
  created:
    - scripts/compile-and-run.sh
  modified:
    - scripts/swift-quality-gate.sh
    - README.md
    - AGENTS.md
key-decisions:
  - "The visible-app smoke test reuses the Swift quality gate before launching the Debug app."
  - "The launch script pins the Kubebar project and scheme to avoid nested workspace ambiguity."
patterns-established:
  - "Use JSON parsing for xcodebuild scheme output instead of ad hoc regex."
requirements-completed: [P04-RUN-VERIFY, GH-7]
duration: inline
completed: 2026-04-21
---

# Phase 04 Plan 01 Summary

**Repeatable local build, test, launch, and process verification for Kubebar**

## Performance

- **Duration:** inline
- **Started:** 2026-04-21
- **Completed:** 2026-04-21
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `./scripts/compile-and-run.sh`.
- Documented the launch smoke test in `README.md` and `AGENTS.md`.
- Fixed the quality gate's scheme parsing and explicit project handling.
- Verified the script launches Kubebar and prints a PID.

## Task Commits

No task commits were created in this run. Execution happened inline in the current worktree.

## Files Created/Modified

- `scripts/compile-and-run.sh` - Builds/tests, quits old Kubebar, launches the built Debug app, and polls for a PID.
- `scripts/swift-quality-gate.sh` - Uses JSON parsing for schemes and honors explicit project/workspace settings.
- `README.md` - Documents the visible-app smoke test.
- `AGENTS.md` - Adds the launch check beside the quality gate.

## Decisions Made

- Used the existing quality gate as the build/test source of truth.
- Used exact bundle id and process name checks instead of broad app termination.

## Deviations from Plan

### Auto-fixed Issues

**1. Quality gate scheme detection was brittle**
- **Found during:** `./scripts/compile-and-run.sh`
- **Issue:** The old regex missed valid Xcode JSON with `"schemes" :`.
- **Fix:** Parse `xcodebuild -list -json` with Ruby JSON.
- **Files modified:** `scripts/swift-quality-gate.sh`
- **Verification:** `./scripts/swift-quality-gate.sh local` passed.

**2. Explicit project selection conflicted with auto workspace discovery**
- **Found during:** `./scripts/compile-and-run.sh`
- **Issue:** The script still auto-selected the nested `.xcodeproj` workspace when a project was specified.
- **Fix:** Explicit project/workspace settings now take priority over auto-discovery.
- **Files modified:** `scripts/swift-quality-gate.sh`, `scripts/compile-and-run.sh`
- **Verification:** `./scripts/compile-and-run.sh` passed.

**Total deviations:** 2 auto-fixed.
**Impact on plan:** Both fixes make the planned launch verification reliable.

## Issues Encountered

- The first sandboxed launch verification could not access Xcode test helper services. Re-ran the same command outside the sandbox with approval, and it passed.

## User Setup Required

None.

## Next Phase Readiness

Future UI work can use `./scripts/compile-and-run.sh` to prove the real menu bar app starts.

---
*Phase: 04-codexbar-inspired-menu-reliability-and-freshness*
*Completed: 2026-04-21*
