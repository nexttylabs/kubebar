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
- Last updated text is visible beside refresh controls.
- Successful data older than `2x` the saved cadence is shown as stale.
- Failed refresh is shown as `Stale`, with last-updated text, safe reason, and
  retry.
- `Retry now` is available when idle in healthy and stale displays.
- `Retry now` is disabled while refresh work is running.
- No next-refresh countdown or progress panel is shown.
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
| Last updated | Menu refresh controls show `Last updated <age>` | pending |
| Healthy idle retry | In a healthy display, `Retry now` is enabled when no refresh is running | pending |
| Stale idle retry | In a stale display, `Retry now` is enabled when no refresh is running | pending |
| Retry while refreshing | `Retry now` is disabled until the current refresh finishes | pending |
| Stale age-out | Data older than `2x` the saved cadence shows `Stale` and `Last refresh is too old` | pending |
| Failed refresh | Previous data remains only with `Stale` state, last-updated text, and a safe stale reason such as `kubectl timed out` or `kubectl failed` | pending |
| No previous data | First refresh failure shows `No previous cluster data` instead of healthy or empty current data | pending |
| Malformed JSON | Malformed JSON shows a short section reason such as `invalid pod JSON` or `invalid event JSON` | pending |
| No countdown | The menu does not show a next-refresh countdown or persistent progress panel | pending |
| Icon states | `OK`, `Watch`, `Bad`, and `Stale` use distinct symbols and labels | pending |

## Notes

- Keep first-screen watchlist rows capped at a glanceable size.
- Do not add deep troubleshooting flow during this phase.
- Do not query Kubernetes Secrets while testing.
