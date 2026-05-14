---
title: Pod Resource Readability
date: "2026-05-14"
category: "docs/solutions/ui-display"
module: "HealthEvaluator"
problem_type: "ui_readability"
component: "display_model"
symptoms:
  - "Pods tab row labels used terse basis text such as req"
  - "Pod resource help text used slash triples that were hard to interpret"
  - "Missing resource values could read like compact numeric data instead of unavailable data"
root_cause: "display_text_contract"
resolution_type: "display_contract_fix"
severity: "low"
related_components:
  - "MenuDisplayModel"
  - "PodsTabView"
  - "MenuDisplayModelTests"
  - "runtime-invariants"
tags:
  - "pod-resource"
  - "resource-usage-visualization"
  - "display-model"
  - "accessibility"
  - "unavailable-data"
reusability: high
next_reuse_scenarios:
  - "Adding compact resource labels to another tab or row type"
  - "Changing hover or accessibility text for resource usage visualization"
  - "Reviewing whether missing metrics look like zero usage"
  - "Polishing Kubernetes display text without changing health semantics"
---

# Pod Resource Readability

## Problem

Kubebar already had useful Pod resource data in the Pods tab, but the display
contract made that data harder to scan than the surrounding health information.
Compact labels used terse basis text such as `req`, while help text compressed
usage, request, and limit into slash triples such as `CPU -/-/-` and
`Mem -/-/-GiB`.

That was technically dense but not glanceable. It also made unavailable data
look like compact numeric output instead of an explicit missing-data state.

## Solution

Keep resource usage visualization display-only, but make both compact and full
text self-describing:

- Row labels name the comparison basis: `CPU 50% of request` and
  `Mem 25% of limit`.
- Full help and accessibility text spell out labeled values:
  `CPU usage 0.5 cores, request 1 core, limit 2 cores`.
- Missing usage, request, or limit values render as `unavailable`, not as
  `0` and not as slash triples.
- Issue text stays before resource text when a Pod needs attention.
- CPU and memory progress values stay separate and do not affect
  `OK`, `Watch`, `Bad`, or `Stale`.

## Why This Works

The row stays compact enough for the menu, but operators no longer need to
decode abbreviations or positional triples. The richer explanation moves into
hover and accessibility text, which fits Kubebar's glanceable menu model without
turning the Pods tab into a resource dashboard.

This keeps the architecture boundary intact: `HealthEvaluator` maps trusted
snapshot data into display text, `MenuDisplayModel` remains the rendering input,
and the UI does not decide cluster health from resource bars.

## Verification

- RED: tests failed when expecting readable resource labels and explicit
  unavailable resource help text.
- GREEN: tests passed after `HealthEvaluator` emitted readable basis wording
  and labeled help/accessibility values.
- Full quality gate passed:
  `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
- Visible smoke launched the app in watch QA state:
  `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer KUBEBAR_QA_STATE=watch ./scripts/compile-and-run.sh`

## Prevention

- When adding resource labels, name the basis in user-facing text unless space
  is genuinely too tight.
- Keep unavailable resource data explicit. Prefer `unavailable` in help and
  accessibility text, and reserve `-` only for compact row labels.
- Do not introduce resource display changes that alter Health category unless a
  planner step explicitly changes health semantics.
- Test compact labels, help text, accessibility text, health non-coupling, and
  separate CPU/memory progress values together.
