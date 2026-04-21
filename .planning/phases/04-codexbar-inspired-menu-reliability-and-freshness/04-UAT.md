# Phase 04 UAT

**Status:** ready for manual checks
**Date:** 2026-04-21

## Completion Criteria

- The app launches from the built Debug bundle.
- First-use setup has a usable window size.
- Context choices load.
- Watchlist choices load after selecting a context.
- Normal menu stays watchlist-first.
- Manual refresh works.
- Refresh cadence is visible and persists.
- Failed refresh is shown as `Stale`, with last-updated text and retry.
- Menu bar icon states are distinguishable without relying on color.

## Checklist

| Test | Expected Result | Status |
| --- | --- | --- |
| Launch with `./scripts/compile-and-run.sh` | Kubebar process starts and PID is printed | passed: PID 16286 |
| Fresh config opens setup | Setup view is readable, not collapsed | pending |
| Context list loads | Context picker shows available Kubernetes contexts | pending |
| Select context | Watchlist target area loads namespace/workload choices | pending |
| Finish setup | Normal menu opens with watchlist-first content | pending |
| Manual refresh | `Retry now` updates the displayed status or stale reason | pending |
| Cadence control | Refresh cadence is visible in setup and menu | pending |
| Cadence persistence | Changed cadence is still selected after relaunch | pending |
| Failed refresh | Previous data remains only with `Stale` state and retry | pending |
| Icon states | `OK`, `Watch`, `Bad`, and `Stale` use distinct symbols and labels | pending |

## Notes

- Keep first-screen watchlist rows capped at a glanceable size.
- Do not add deep troubleshooting flow during this phase.
- Do not query Kubernetes Secrets while testing.
