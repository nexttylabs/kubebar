# Operator Verification

## Scope

This guide covers operator-facing checks for the menu states required by Phase 07. It verifies the real menu-bar app shell with deterministic QA states and does not replace the automated test suite.

## QA State Commands

- `./scripts/compile-and-run.sh --qa-state healthy`
- `./scripts/compile-and-run.sh --qa-state watch`
- `./scripts/compile-and-run.sh --qa-state bad`
- `./scripts/compile-and-run.sh --qa-state stale-refresh-failure`
- `./scripts/compile-and-run.sh --qa-state stale-age-out`
- `./scripts/compile-and-run.sh --qa-state first-use`
- `./scripts/compile-and-run.sh --qa-state empty-watchlist`
- `./scripts/compile-and-run.sh --qa-state kubectl-failure`

## Evidence Rules

Screenshots belong under `docs/assets/qa/` with these names:

- `phase-07-healthy.png`
- `phase-07-watch.png`
- `phase-07-bad.png`
- `phase-07-stale-refresh-failure.png`
- `phase-07-stale-age-out.png`
- `phase-07-first-use.png`
- `phase-07-empty-watchlist.png`
- `phase-07-kubectl-failure.png`

Evidence must not include raw command transcripts, tokens, kubeconfig paths, full JSON, or sensitive cluster details.

## State Checklist

| State | Expected visible behavior | Evidence path |
|-------|---------------------------|---------------|
| Healthy | Menu shows OK with healthy counters and watched namespaces. | `docs/assets/qa/phase-07-healthy.png` |
| Watch | Menu shows Watch with warning context and non-healthy attention. | `docs/assets/qa/phase-07-watch.png` |
| Bad | Menu shows Bad and prioritizes the broken watched target. | `docs/assets/qa/phase-07-bad.png` |
| Stale refresh failure | Menu shows Stale while preserving last known status. | `docs/assets/qa/phase-07-stale-refresh-failure.png` |
| Stale age-out | Menu shows Stale because the last successful refresh is too old. | `docs/assets/qa/phase-07-stale-age-out.png` |
| first-use | Menu shows setup before any saved context exists. | `docs/assets/qa/phase-07-first-use.png` |
| empty-watchlist | Menu shows setup because the QA fixture context has no selected namespaces. | `docs/assets/qa/phase-07-empty-watchlist.png` |
| kubectl failure | Menu shows Stale with a safe failure message and retained prior status. | `docs/assets/qa/phase-07-kubectl-failure.png` |

## When To Mark pending-human-verification

Use `pending-human-verification` when screenshots are blocked, the menu cannot be opened during automation, or visible behavior has not been personally checked. Keep the row pending until a screenshot or equivalent human-visible record exists.
