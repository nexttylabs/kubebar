# Kubebar Handoff

## Current State

- Plan: `docs/plans/2026-05-15-003-fix-k9s-handoff-entry-placement-plan.md`
- Status: complete
- Completed steps: U1 `k9s list-level handoffs use group-level entries.`
- Latest review: pass

## Verification

- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/compile-and-run.sh --qa-state bad`
- Computer Use Bad QA visible check

## Notes

- Overview Watch/Bad QA fixtures retain an `Open in k9s` handoff target.
- Pod namespace headers now expose namespace Pods view/list handoffs.
- Pod rows no longer expose list-level k9s handoffs.
- Nodes summary now exposes the Nodes view/list handoff.
- Node rows no longer expose list-level k9s handoffs.
- Launcher arguments keep app-owned context and namespace/resource view values.
- Stale/setup/unavailable gating remains covered.
- No known blockers.
