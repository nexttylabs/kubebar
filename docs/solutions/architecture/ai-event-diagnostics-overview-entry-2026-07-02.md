---
module: architecture
tags:
  - kubebar
  - ai-diagnostics
  - warning-events
  - menu-bar
  - kubectl
problem_type: scoped-ai-event-diagnostics
reusability: medium
key_files:
  - KubebarCore/Models/MenuDisplayModel.swift
  - KubebarCore/Models/AIEventDiagnosis.swift
  - KubebarCore/Services/HealthEvaluator.swift
  - KubebarCore/Services/WarningEventDiagnosticReader.swift
  - KubebarCore/Services/AIEventDiagnosticRequester.swift
  - Kubebar/MenuBarViewModel.swift
  - Kubebar/Views/OverviewTabView.swift
  - docs/architecture/runtime-invariants.md
next_reuse_scenarios:
  - Adding another AI diagnostic surface that must use a structured display-model target instead of parsing UI text.
  - Extending Warning Event diagnosis beyond Overview while preserving exact event-group matching.
  - Reviewing AI features that submit fresh Kubernetes context to an external provider.
---

# AI Event Diagnostics Need Explicit Warning Targets and Fresh Reads

## Problem

Kubebar already grouped Warning Events for display, but the rows were originally
presentation-only. Adding an AI action from `Overview` `Recent Warnings` needed
three boundaries to stay safe:

- the UI must not infer a diagnostic target by parsing displayed location text;
- the AI payload must use fresh `kubectl` event data rather than stale snapshot
  rows;
- the event-diagnostic path must remain distinct from Pod-log diagnosis so it
  does not silently send logs or broaden the privacy boundary.

## Solution

Use an explicit display-model target and a separate event-only diagnostic path.

- Add a `WarningEventDiagnosticTarget` value derived by `HealthEvaluator` from
  the same warning group key used for display grouping: `namespace`,
  `objectKind`, `objectName`, and `reason`.
- Expose the AI action only when the row has a structured diagnostic target.
  Do not let SwiftUI views parse `location`, `helpText`, or accessibility text.
- On click, reread Warning Events through the app-owned context/kubeconfig
  boundary, filter by exact target key, sort newest first, and cap the provider
  payload to the latest 5 matching Warning Events.
- Keep the provider requester event-only: redact messages, include structured
  event fields, and exclude Pod logs, raw cluster JSON, kubeconfig content,
  raw command transcripts, and automatic command execution.
- Keep the result transient in `MenuBarViewModel` and scoped to the active
  warning target. Provide warning-specific accessibility labels and a dismiss
  control so the inline panel does not permanently crowd the glanceable menu.

## Evidence

- `swift test --filter AIProviderConnectionTesterTests` passed.
- `swift test --filter AIEventDiagnosticRequesterTests` passed.
- `swift test --filter WarningEventDiagnosticReaderTests` passed.
- `swift test --filter MenuDisplayModelTests` passed.
- `swift build` passed.
- `./scripts/swift-quality-gate.sh local` passed.
- `rtk git diff --check` passed.
- UI review found same-boundary accessibility/dismissal issues; both were fixed
  and the quality gate passed again.

## Reuse Notes

For future AI troubleshooting surfaces, start by adding a small explicit target
value at the display-model boundary. If the view has to parse a display string
to find what to diagnose, the boundary is too weak. Fresh reads should go
through injectable command services, not directly from SwiftUI. Provider
requesters should be input-specific instead of overloading an existing requester
with a broader privacy contract.

## Reusability Critique

- Falsifiability: this lesson is too local if future Kubernetes Event APIs stop
  supporting the fields needed for exact matching or if Kubebar replaces
  snapshot/display grouping with a canonical event identity store.
- Evidence trail: the guidance is supported by focused reader/requester/model
  tests, full quality gate, diff check, and UI review follow-up. It is not
  supported by automated VoiceOver traversal or screenshots.
- Architecture entropy resistance: this belongs in `docs/solutions/architecture`
  because it captures ownership boundaries between display targets, fresh
  command reads, provider requests, and transient UI state. It should not become
  a generic rule that every display row needs an AI target.
