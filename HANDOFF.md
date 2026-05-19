# Kubebar Handoff

## Current State

- Plan: `docs/plans/2026-05-19-001-feat-start-at-login-setting-plan.md`
- Status: complete
- Completed steps: U1 `Start at Login can be controlled from Settings.`
- Latest review: pass

## Verification

- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer KUBEBAR_QA_STATE=setup ./scripts/compile-and-run.sh`

## Notes

- Settings now includes a `Start at Login` toggle.
- The toggle uses an injectable Start at Login coordinator in `KubebarCore`
  and a production `SMAppService.mainApp` boundary in the app target.
- Failed login item updates roll the displayed state back to the actual system
  status and show a recoverable Settings message.
- Start at Login remains separate from saved Kubernetes context, watchlist,
  refresh cadence, stale handling, and Health category.
- Visible smoke launched the app in `setup` QA state, opened Settings, and
  confirmed the Start at Login toggle in the accessibility tree.
- No known blockers.
