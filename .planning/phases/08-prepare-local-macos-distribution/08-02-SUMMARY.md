---
phase: 08-prepare-local-macos-distribution
plan: "02"
subsystem: local-distribution-docs
tags: [docs, macos, install, uat]

requires:
  - phase: 08-prepare-local-macos-distribution
    plan: "01"
    provides: local install script
provides:
  - README install, update, uninstall, and reset instructions
  - Changelog entry for local install support
  - Phase 08 UAT checklist and evidence
affects: [README, changelog, uat]

tech-stack:
  added: []
  patterns:
    - Keep install, update, uninstall, and config reset as separate documented actions
    - Record distribution proof in UAT without adding menu UI automation

key-files:
  created:
    - .planning/phases/08-prepare-local-macos-distribution/08-UAT.md
    - .planning/phases/08-prepare-local-macos-distribution/08-02-SUMMARY.md
  modified:
    - README.md
    - CHANGELOG.md

key-decisions:
  - "README keeps app uninstall separate from Kubebar config reset."
  - "Config reset documentation names only ~/Library/Application Support/Kubebar/config.json."
  - "UAT records human launch as optional because issue #8 is distribution-focused."

requirements-completed: [ISSUE-8-AC1, ISSUE-8-AC2, ISSUE-8-AC3, ISSUE-8-AC4]

duration: 14 min
completed: 2026-04-22
---

# Phase 08 Plan 02: Local Install Documentation Summary

**Kubebar's local install path is now documented with safe update, uninstall, reset, and verification guidance.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-04-22T02:55:00Z
- **Completed:** 2026-04-22T03:09:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added a README `Local Install` section with install, update, uninstall, reset, and local distribution boundary guidance.
- Documented the config file at `~/Library/Application Support/Kubebar/config.json`.
- Recorded that config reset does not touch kubeconfig, Kubernetes credentials, or cluster resources.
- Added a changelog entry for local install support.
- Created Phase 08 UAT with automated verification, bundle proof, documentation checks, scope guards, and optional human launch verification.

## Task Commits

1. **Tasks 1 and 2: README install/update/uninstall/reset docs** - `0138a09` (docs)
2. **Task 3: Changelog and Phase 08 UAT** - `ab4c9e7` (docs)

## Files Created/Modified

- `README.md` - Adds local install, update, uninstall, config reset, and distribution boundary instructions.
- `CHANGELOG.md` - Adds the local install support note under `[Unreleased]`.
- `.planning/phases/08-prepare-local-macos-distribution/08-UAT.md` - Records verification evidence and scope guards.
- `.planning/phases/08-prepare-local-macos-distribution/08-02-SUMMARY.md` - Records plan results.

## Decisions Made

- Kept local install documentation near the existing build/test instructions.
- Used direct shell commands for uninstall and reset so users can see exactly what is removed.
- Kept public distribution terms explicitly out of scope in README and UAT.

## Deviations from Plan

### Execution Adjustments

**1. README tasks were committed together**
- **Found during:** Documentation execution.
- **Issue:** Task 1 and Task 2 both edited the same README section.
- **Fix:** Committed the README update as one docs commit to keep the section coherent.
- **Files modified:** `README.md`
- **Verification:** All README acceptance greps passed.
- **Committed in:** `0138a09`

### Auto-fixed Issues

None.

---

**Total deviations:** 1 execution adjustment, 0 auto-fixed code issues.
**Impact on plan:** No scope changed. All issue #8 documentation requirements are covered.

## Issues Encountered

None.

## Verification

- `rg -n "## Local Install|### Install|### Update|### Uninstall|### Reset Kubebar Config|### Local Distribution Boundary" README.md` - passed.
- `rg -n "\\./scripts/install-local.sh|~/Applications/Kubebar.app|KUBEBAR_INSTALL_DIR=/Applications \\./scripts/install-local.sh" README.md` - passed.
- `rg -n "running the same install command again|notarization|Homebrew|Sparkle|pkg|dmg|public release automation" README.md` - passed.
- `rg -n "tell application id \"com.nextty.kubebar\" to quit|\\$HOME/Applications/Kubebar.app" README.md` - passed.
- `rg -n "~/Library/Application Support/Kubebar/config.json|\\$HOME/Library/Application Support/Kubebar/config.json" README.md` - passed.
- Negative credential-removal grep for `.kube` and `KUBECONFIG` removal commands in README - passed.
- Changelog local install bullet check - passed.
- Phase 08 UAT section and evidence checks - passed.
- `./scripts/install-local.sh` - passed during Plan 01 final verification.

## Known Stubs

None.

## Threat Flags

None. Documentation removes only app bundle or Kubebar config paths and explicitly avoids Kubernetes credential paths.

## User Setup Required

None.

## Next Phase Readiness

Ready for phase-level verification. Issue #8 implementation, documentation, and UAT evidence are present.

## Self-Check: PASSED

- Summary file exists.
- Task commits found: `0138a09`, `ab4c9e7`.
- README, CHANGELOG, and UAT acceptance checks passed.
