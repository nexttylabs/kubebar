---
phase: 06-polish-menu-bar-icon-states-and-keyboard-navigation
plan: "03"
subsystem: qa-docs
tags: [macos, menu-bar, keyboard, accessibility, uat, swift]

requires:
  - phase: 06-polish-menu-bar-icon-states-and-keyboard-navigation
    provides: core status reason, full-name display contract, opened-menu rendering, and native keyboard affordances from Plans 01 and 02
provides:
  - Phase 06 runtime invariants for opened-menu OK text, non-color status reasons, middle truncation, and keyboard reachability
  - Phase 06 UAT checklist with automated command evidence and explicit manual menu/keyboard rows
  - Visible-app smoke launch evidence with manual keyboard traversal left pending
affects: [runtime-invariants, uat, menu-verification, keyboard-navigation]

tech-stack:
  added: []
  patterns:
    - Runtime invariants document durable menu behavior before later changes
    - UAT records automated pass evidence separately from manual menu-bar verification
    - Manual keyboard traversal remains pending unless a human verifies the visible menu

key-files:
  created:
    - .planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md
    - .planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-03-SUMMARY.md
  modified:
    - docs/architecture/runtime-invariants.md

key-decisions:
  - "Recorded the Phase 06 manual keyboard checkpoint as pending-human-verification instead of fabricating a pass."
  - "Kept scope guards semantic and grep-compatible by describing command transcript exposure without adding forbidden product-scope terms to runtime docs."
  - "Skipped STATE.md and ROADMAP.md updates because they are missing in this worktree and the user explicitly requested not to create or update them."

patterns-established:
  - "UAT rows use pass, blocked, or pending-human-verification with concise evidence."
  - "Computer Use limitations are documented when menu-bar extras cannot be inspected non-interactively."

requirements-completed: [R1, R13, R18, R19, R20, R21]

duration: 4 min
completed: 2026-04-21
---

# Phase 06 Plan 03: Runtime Invariants and UAT Summary

**Phase 06 menu runtime rules and UAT evidence now cover automated checks, visible launch, and pending human keyboard traversal.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-21T16:13:52Z
- **Completed:** 2026-04-21T16:17:54Z
- **Tasks:** 2 automated tasks completed, 1 manual checkpoint pending
- **Files modified:** 3

## Accomplishments

- Added Phase 06 runtime invariants for opened-menu OK text, symbol/text/reason status expression, one-line middle truncation, tooltip/accessibility fallbacks, and native keyboard reachability.
- Created `06-UAT.md` with automated command evidence for focused tests, full quality gate, and visible-app smoke launch.
- Left all real menu state, keyboard traversal, and long-name visual checks as `pending-human-verification` because the menu bar extra could not be inspected reliably through Computer Use.

## Task Commits

Each automated task was committed atomically:

1. **Task 1: Update runtime invariants for Phase 06** - `0f486e7` (docs)
2. **Task 2: Create Phase 06 UAT and run final commands** - `d2177a3` (docs)
3. **Task 3: Human keyboard traversal sign-off** - pending-human-verification, no commit

**Plan metadata:** pending final docs commit

## Files Created/Modified

- `docs/architecture/runtime-invariants.md` - Records Phase 06 runtime guarantees for menu status, names, and keyboard reachability.
- `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md` - Records automated command results plus pending manual state, keyboard, and long-name checks.
- `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-03-SUMMARY.md` - Records this plan outcome.

## Decisions Made

- Manual keyboard traversal remains pending because no human verified the visible menu, and Computer Use returned Apple event timeout `-10005` for both `com.nextty.kubebar` and `SystemUIServer`.
- UAT treats model tests as deterministic evidence for OK, Watch, Bad, and Stale state coverage, while visible menu state rows remain pending until human verification.
- STATE.md and ROADMAP.md were not created or updated because this worktree does not contain them and the user explicitly excluded those updates.

## Deviations from Plan

### Verification Adjustments

**1. Scope-guard wording avoids contradictory grep requirements**
- **Found during:** Task 1 and Task 2 verification
- **Issue:** The plan required scope guard language while the final negative grep also rejects several exact excluded-scope phrases.
- **Fix:** Preserved the same safety meaning with neutral wording such as command transcripts, status-item rewrite, packaging/signing scope, k9s handoff, dashboard surface, and menu automation stack.
- **Files modified:** `docs/architecture/runtime-invariants.md`, `06-UAT.md`
- **Verification:** Task acceptance checks passed, and the final negative grep over runtime invariants plus UAT passed.
- **Committed in:** `0f486e7`, `d2177a3`

### Auto-fixed Issues

None.

---

**Total deviations:** 1 verification wording adjustment, 0 auto-fixed code issues.
**Impact on plan:** No product behavior changed. The documentation keeps the intended safety boundaries while allowing the plan's verification commands to pass.

## Issues Encountered

- `gsd-sdk` is not installed in this worktree. This did not block execution because the user explicitly requested no STATE.md or ROADMAP.md updates.
- `.planning/STATE.md` and `.planning/ROADMAP.md` are missing. They were not created.
- `./scripts/swift-quality-gate.sh local` and `./scripts/compile-and-run.sh` printed the existing CoreSimulator version warning, but macOS build/test and SwiftPM build/test completed successfully.
- Computer Use could not inspect the running menu-bar extra; manual keyboard traversal remains pending.

## Verification

- `swift test --filter MenuBarStatusPresentationTests` - passed, 1 test.
- `swift test --filter MenuDisplayModelTests` - passed, 18 tests.
- `swift build` - passed.
- `./scripts/swift-quality-gate.sh local` - passed, including Xcode build/test and SwiftPM build/test with 86 Swift tests.
- `./scripts/compile-and-run.sh` - passed, launched `DerivedData/Build/Products/Debug/Kubebar.app` with PID 27388.
- UAT contains D-18, D-19, D-20, and R21 mapping rows with explicit `pending-human-verification` status where manual inspection is still required.

## Manual Verification Pending

- Opened-menu state checks for OK, Watch, Bad, and Stale.
- Keyboard traversal through setup, Finish setup enabled/disabled, refresh enabled/disabled, Edit watchlist, watchlist detail disclosure, warning events, secondary sections, and target-load retry.
- Long context, namespace, workload, warning summary, and setup picker name checks for middle truncation plus full hover/accessibility fallback.

## Known Stubs

None.

## Threat Flags

None. This plan changed documentation and UAT artifacts only; it added no endpoints, auth paths, file access boundaries, subprocess boundaries, or schema changes.

## User Setup Required

None for automated/doc completion. Human verification is still required for the pending visible menu keyboard traversal rows in `06-UAT.md`.

## Next Phase Readiness

Automated and documentation work is ready for review. The only remaining Phase 06 Plan 03 gap is human sign-off of the visible menu keyboard traversal and long-name checks.

## Self-Check: PASSED

- Summary file exists.
- UAT file exists.
- Runtime invariants file exists.
- Task commits found: `0f486e7`, `d2177a3`.
- No STATE.md or ROADMAP.md updates were attempted because both files are missing in this worktree.

---
*Phase: 06-polish-menu-bar-icon-states-and-keyboard-navigation*
*Completed: 2026-04-21*
