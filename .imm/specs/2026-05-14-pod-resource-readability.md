---
title: Pod resource readability
date: 2026-05-14
status: planned
origin: imm-brainstorm screenshot review
---

# Pod Resource Readability

## Summary

The Pods tab already shows current-snapshot CPU and memory usage for watched
Pods. The screenshot review shows that the row now has enough data, but the
resource wording and hover detail are still harder to scan than the rest of the
menu.

This slice improves how existing Pod resource usage visualization is phrased
and inspected. It does not add new metrics, alerts, trends, or health rules.

## Goals

- Resource labels use plain wording instead of abbreviation-only basis text.
- Hover/help text separates identity, readiness, CPU, memory, and unavailable
  resource data into readable parts.
- Missing resource values remain explicit without looking like healthy zero
  usage.
- Compact Pod rows preserve Pod name, ready count, and issue text priority.
- CPU and memory remain separate current-snapshot indicators.

## Non-Goals

- No new Kubernetes reads.
- No historical charts, sparklines, trends, or time-series storage.
- No resource-pressure alerting.
- No changes to `OK`, `Watch`, `Bad`, or `Stale` evaluation.
- No per-container Pod resource breakdown.
- No external monitoring integration.

## Requirements

- R1. `MenuDisplayModel` remains the only rendering input for Pods tab rows.
- R2. Resource labels must avoid relying only on terse basis abbreviations such
  as `req` when a clearer compact phrase can fit.
- R3. CPU and memory labels must keep their comparison basis visible when one
  is available.
- R4. Hover/help text must not expose ambiguous compact triples such as
  `Mem 0/-/-GiB` when the usage or basis is unavailable.
- R5. Unavailable resource data must be displayed as unavailable or omitted
  from a basis comparison, never as a healthy zero.
- R6. Pod issue text must remain visually and semantically higher priority than
  resource text.
- R7. Resource usage visualization must remain display-only and must not change
  any Health category.
- R8. CPU and memory progress values must stay separate.
- R9. Layout must keep the ready count aligned and Pod names truncating cleanly.
- R10. Accessibility labels must include the same complete resource details as
  help text.

## Verification Expectations

- Display-model tests cover readable resource labels for request, limit, raw,
  and unavailable cases.
- Display-model tests cover hover/help text for missing resource values without
  ambiguous zero-like triples.
- Regression tests prove high Pod resource usage does not change Health
  category.
- `./scripts/swift-quality-gate.sh local` passes.
- A visible-app smoke check is used to inspect the Pods tab when local macOS
  launch is available.
