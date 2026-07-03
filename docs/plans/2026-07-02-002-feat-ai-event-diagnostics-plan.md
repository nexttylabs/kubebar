---
title: "feat: add Overview Recent Warnings AI event diagnostics"
type: feat
status: planned
date: 2026-07-02
origin: .imm/specs/2026-07-02-ai-event-diagnostics.md
---

# feat: add Overview Recent Warnings AI event diagnostics

## Summary

- Summary: Add a manual AI diagnosis action only to `Overview` `Recent Warnings` rows that rereads fresh Warning Events through `kubectl`, filters by exact `namespace`, `objectKind`, `objectName`, and `reason`, sends the latest 5 matching events to the configured AI Provider, and renders a transient Markdown diagnosis.

This plan is a new executable slice after the completed Pod AI diagnostics slice. The previous Pod slice deliberately excluded primary Warning Events diagnosis. This slice keeps event diagnosis event-only: no Pod logs, no Events tab entry, no automatic remediation, and no health-category side effects.

## Current Slice

- Roadmap source: `.imm/specs/2026-07-02-ai-event-diagnostics.md`
- Execution scope: Overview `Recent Warnings` row action, fresh Warning Event read boundary, exact warning-group matching, event diagnostic prompt/request boundary, transient diagnosis UI state, provider/event text redaction, docs/tests
- Deferred phases: Events tab row diagnosis, Pod-log fallback from event diagnosis, footer/global cluster diagnosis, report persistence/history, chat UX, and auto-remediation are outside this plan
- This is not a global AI cluster diagnosis roadmap.

## Task

- Type: feat
- Scope: Overview Recent Warnings, Warning Event `kubectl` read, AI provider request service, transient report rendering, docs/tests
- Owner: imm-work
- Verification: focused Swift tests, Swift build, and full Swift quality gate when practical

## Output Language

Spec and Plan prose are English. Code identifiers, schema fields, CLI commands, file paths, provider names, API names, enum cases, Markdown headings, and Immune-Brain fields remain literal.

## Origin

The user reported that no AI diagnosis entry exists in warning events. The current Pod AI diagnostics plan intentionally shipped Pod-level diagnostics only and deferred warning-event diagnosis. The user then clarified the intended new scope:

- Add the entry only to `Overview` `Recent Warnings`.
- Use `namespace + objectKind + objectName + reason` to identify related Warning Events.
- Send the latest 5 matching warning events to AI.

## Brainstorm manifest

- `BR-REQ-001`: Add manual AI diagnosis entry only to Overview `Recent Warnings`.
- `BR-REQ-002`: Match related events by `namespace + objectKind + objectName + reason`.
- `BR-REQ-003`: Send the latest 5 matching warning events to the configured AI Provider.
- `BR-REQ-004`: Use fresh `kubectl` event reads through Kubebar’s app-owned context/kubeconfig rules.
- `BR-REQ-005`: AI event diagnosis is display/help behavior only and must not affect health evaluation.
- `BR-OUT-001`: Do not add the entry to Events tab in this slice.
- `BR-OUT-002`: Do not read Pod logs for this event diagnosis.
- `BR-OUT-003`: Do not execute AI-suggested `kubectl` commands.
- `BR-DEC-001`: Diagnose warning-event groups, not individual Kubernetes Event object names.
- `BR-DEC-002`: Scope payload to the latest 5 matching Warning Events.

## Brainstorm Trace

| Item | Status | Plan coverage |
| --- | --- | --- |
| `BR-REQ-001` | covered_by_step | Step 1 wires the action only into `Overview` `Recent Warnings`. |
| `BR-REQ-002` | covered_by_step | Step 1 adds an exact diagnostic target key and matching logic. |
| `BR-REQ-003` | covered_by_step | Step 1 caps provider input to the latest 5 matching Warning Events. |
| `BR-REQ-004` | covered_by_step | Step 1 adds a fresh `kubectl` Warning Event read boundary using app-owned context/kubeconfig. |
| `BR-REQ-005` | covered_by_step | Step 1 keeps results transient and outside health evaluation. |
| `BR-OUT-001` | out_of_scope | Events tab diagnosis is explicitly excluded from this slice to keep the entry limited to Overview. |
| `BR-OUT-002` | out_of_scope | Pod logs are excluded; this is event-only diagnosis. |
| `BR-OUT-003` | out_of_scope | Auto-execution is excluded; suggested commands remain text only. |
| `BR-DEC-001` | captured_as_decision | The diagnostic target is a warning-event group key, not a Kubernetes Event object name. |
| `BR-DEC-002` | captured_as_decision | The provider payload is capped at the latest 5 matching Warning Events. |

## Research

- `CONTEXT.md` defines `AI Diagnostic Assistant`, `AI Provider configuration`, `AI Provider API key`, `AI Pod diagnostic input`, `Pod Micro-Logs Drawer`, app-owned context, and effective kubeconfig rules. This slice should add event-diagnostic vocabulary while preserving the existing AI safety boundary.
- `docs/architecture/runtime-invariants.md` requires AI behavior to remain display/help only, API keys to stay in Keychain, AI Test Connection to send no Kubernetes data, and AI diagnosis not to affect Health category.
- `.imm/memory/current_iteration.json` shows the previous Pod AI diagnostics plan is closed. A new slice is appropriate because this scope was deferred/out-of-scope in the completed Pod plan.
- `Kubebar/Views/OverviewTabView.swift` renders `RecentWarningsOverviewView` from `display.overview.recentWarnings` and currently uses `WarningEventRowView(row:)` without an action callback.
- `Kubebar/Views/WarningEventsView.swift` owns the shared `WarningEventRowView` rendering used by Overview and Events tab. The implementation should avoid accidentally adding the AI entry to Events tab.
- `KubebarCore/Models/MenuDisplayModel.swift` currently exposes `WarningEventDisplay` display fields but not an explicit public diagnostic target key. A small value type is needed so SwiftUI does not infer target semantics from strings.
- `KubebarCore/Services/HealthEvaluator.swift` groups warnings by `reason`, `objectKind`, `namespace`, and `objectName`; this matches the user-confirmed diagnostic key.
- `KubebarCore/Services/KubectlClusterReader.swift` already reads Warning Events with `kubectl get events --all-namespaces --field-selector type=Warning -o json`, decodes both core and events.k8s.io-style fields, and sanitizes failures. A finite event diagnostic reader should reuse this command/environment pattern without exposing raw transcripts.
- `KubebarCore/Services/AIPodDiagnosticRequester.swift` provides the provider request pattern, credential validation, provider-specific body construction, safe provider error messages, and `AIDiagnosticRedactor` helper.
- Read-only planner probe confirmed the key implementation surfaces: Overview UI, shared warning row view, display model warning grouping, kubectl event read boundary, and AI requester/test patterns.

## Decisions

- Create a new event-only diagnostic path instead of extending `AIPodDiagnosticContext` or reading Pod logs.
- Put the action only in `Overview` `Recent Warnings`; the Events tab continues to render warning rows without AI controls.
- Represent the AI target explicitly as a value derived from `namespace`, `objectKind`, `objectName`, and `reason`; views must pass this value instead of parsing display strings.
- Reread Warning Events at click time and filter the fresh records by exact target key. If no matching events remain, show a safe no-match failure rather than diagnosing stale rows.
- Send at most the latest 5 matching Warning Events, sorted by observed timestamp with a deterministic fallback for missing timestamps.
- Reuse the existing AI Provider configuration, Keychain credential store, HTTP client abstraction, and redaction helper.
- Keep the generated report transient in `MenuBarViewModel` state; do not persist reports or event payloads.
- Render Markdown using the existing basic report surface pattern unless implementation finds a smaller reusable component path.
- Keep all AI event diagnosis results outside `HealthEvaluator`, `MenuDisplayModel` health categories, Health State Shift Alerts, watchlist ordering, and menu bar icon state.

## Assumptions

- `namespace` may be absent for cluster-scoped objects; exact matching treats nil and empty as distinct safe values rather than guessing.
- `WarningEventDisplay` rows without enough structured target fields should not expose the AI action.
- Provider responses are plain text/Markdown; a full Markdown parser dependency is not required for this slice.
- Focused tests can cover Core reader/requester behavior; app-target UI wiring is primarily build/quality-gate verified because current package tests target `KubebarCore`.

## Planning Quality Gate Notes

- Contract surface: `CONTEXT.md`, `.imm/specs/2026-07-02-ai-event-diagnostics.md`, `docs/architecture/runtime-invariants.md`, `KubebarCore/Models/MenuDisplayModel.swift`, `KubebarCore/Models/ClusterSnapshot.swift`, `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarCore/Services/AIProviderConnectionTester.swift`, `KubebarCore/Services/AIPodDiagnosticRequester.swift`, `Kubebar/MenuBarViewModel.swift`, `Kubebar/Views/OverviewTabView.swift`, `Kubebar/Views/WarningEventsView.swift`, and focused tests.
- Compatibility: no persisted config migration is needed; the feature uses existing AI Provider configuration and stores no diagnosis history.
- Interruption recovery: if service/requester tests fail, keep the UI action unexposed. If app-target UI wiring fails, revert the view/view-model changes while preserving coherent Core tests or revert the whole slice.
- Rollback path: revert new event diagnostic models/services, ViewModel/UI wiring, docs/spec/plan/changelog, and tests. No Kubernetes resources or persisted cluster data are modified.
- Verification strength: tests must fail if matching is substring-based, if more than 5 events are submitted, if stale snapshot rows are submitted without a fresh read, if provider payload contains Pod logs/raw cluster JSON/raw transcripts, or if credentials leak into visible failures.
- Brainstorm traceability: every `BR-*` item is mapped in `Brainstorm Trace`; there are no open `BR-Q-*` items.

## Devil's Advocate Audit

### Rollback resilience

The plan keeps event diagnosis behind an explicit Overview row action and injectable boundaries. If the reader/requester layer fails, the UI action can remain absent. If UI wiring fails, reverting `MenuBarViewModel`, `OverviewTabView`, and `WarningEventsView` removes the feature without changing refresh health evaluation or existing Pod AI diagnostics. No step mutates Kubernetes resources.

### Verification vanity

A button-existence test would be vanity. Verification must inspect generated `kubectl` command arguments/environment, exact target matching, latest-5 cap, fresh-read behavior, provider request bodies, redacted event messages, safe error text, and that Events tab does not receive the action. The full quality gate confirms Xcode and SwiftPM surfaces compile with the new files.

### Spec dilution detection

The plan preserves the user-confirmed differences from the prior Pod slice: Overview-only, event-only, exact key matching, latest 5 Warning Events, and no Events tab entry. It does not silently substitute existing Pod diagnosis or broaden into global/footer diagnosis because that would violate `BR-OUT-*` items.

## Scope Boundaries

- In scope: Overview `Recent Warnings` row action, exact warning-event diagnostic target, fresh Warning Event read, latest-5 matching event payload, redacted provider request, transient Markdown report, safe failures, docs/tests.
- Out of scope: Events tab AI action, Pod log reads, global cluster diagnosis, footer shortcut, automatic/background diagnosis, auto-executed fixes, Secret reads, kubeconfig transmission, full raw kubectl transcripts, raw cluster JSON, persistence/history, chat UX, and advanced provider settings.

## Deferred Work

- Add Events tab row-level diagnosis only if a later plan intentionally expands the entry point beyond Overview.
- Add an optional Pod-log follow-up from event diagnosis only after the product explicitly asks for event-to-Pod escalation and user-approved Pod log submission in that flow.
- Add richer Markdown rendering or copy-code-block controls if the basic report surface is not enough.
- Add enterprise privacy docs after the first event-diagnostic slice ships.

## Implementation Units

### Step 1

- Step ID: U1
- Result: `Overview` `Recent Warnings` manually renders a safe AI diagnosis from the latest 5 fresh matching Warning Events.
- Verification: swift test --filter AIProviderConnectionTesterTests && swift test --filter AIEventDiagnosticRequesterTests && swift test --filter WarningEventDiagnosticReaderTests && swift test --filter MenuDisplayModelTests && swift build && ./scripts/swift-quality-gate.sh local && rtk git diff --check
- Depends on: None
- Test scenarios: Overview Recent Warnings exposes the AI action while Events tab rows do not; the diagnostic reader builds a fresh `kubectl --context <context> get events --all-namespaces --field-selector type=Warning -o json` style read with effective kubeconfig overrides; exact matching uses `namespace`, `objectKind`, `objectName`, and `reason` without substring fallback; provider input is sorted newest first and capped at 5 matching Warning Events; no matching fresh events produces a safe retryable failure; event messages are redacted before provider submission; missing provider model/key/base URL returns safe local failure; provider/network errors never expose API keys/Bearer tokens/raw response bodies; request body includes structured event context and required Markdown instructions but no Pod logs, kubeconfig content, raw cluster JSON, or raw kubectl transcript; diagnosis state supports loading, success, retryable failure, unavailable configuration, and stale-display disclosure; AI suggested commands remain text only and no mutation command is executed by Kubebar; docs preserve Health category independence
- Discovery cache: Kubebar/Views/OverviewTabView.swift (Overview Recent Warnings UI); Kubebar/Views/WarningEventsView.swift (shared warning row view and Events-tab separation risk); KubebarCore/Models/MenuDisplayModel.swift (display-ready warnings and diagnostic target value); KubebarCore/Services/HealthEvaluator.swift (warning grouping key); KubebarCore/Services/KubectlClusterReader.swift (Warning Event kubectl decode/command pattern); KubebarCore/Services/AIProviderConnectionTester.swift (provider validation pattern); KubebarCore/Services/AIPodDiagnosticRequester.swift (diagnostic requester/redaction pattern); Kubebar/MenuBarViewModel.swift (transient AI state and app-owned config); docs/architecture/runtime-invariants.md (runtime safety contract); CONTEXT.md (canonical AI diagnostic vocabulary)

**Goal:** Deliver the full user-visible Overview warning AI diagnosis loop in one coherent feature.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14

**Dependencies:** None

**Files:**
- Modify: `CONTEXT.md`
- Modify: `docs/architecture/runtime-invariants.md`
- Add or modify: `KubebarCore/Models/AIEventDiagnosis.swift`
- Add or modify: `KubebarCore/Models/MenuDisplayModel.swift`
- Add: `KubebarCore/Services/WarningEventDiagnosticReader.swift`
- Add: `KubebarCore/Services/AIEventDiagnosticRequester.swift`
- Modify: `KubebarCore/Services/KubectlClusterReader.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify: `Kubebar/Views/OverviewTabView.swift`
- Modify: `Kubebar/Views/WarningEventsView.swift`
- Modify: `Kubebar.xcodeproj/project.pbxproj`
- Add: `KubebarTests/Services/WarningEventDiagnosticReaderTests.swift`
- Add: `KubebarTests/Services/AIEventDiagnosticRequesterTests.swift`
- Modify/Add: `KubebarTests/Models/MenuDisplayModelTests.swift`
- Add: `changelog.d/ai-event-diagnostics.added.md`

**Approach:**
- Add Core value types for an event diagnostic target, event diagnostic context, event diagnosis state/result, and latest matching event summaries.
- Add a finite Warning Event diagnostic reader using `CommandRunning` and `KubectlEnvironment` to read Warning Events with the app-owned context, decode structured event records, filter by exact target key, sort newest first, and cap at 5.
- Add `AIEventDiagnosticRequester` that loads the provider API key from the credential store, validates model/base URL, redacts event messages, constructs provider-specific requests, and returns Markdown text or safe errors.
- Thread transient event diagnosis state through `MenuBarViewModel`, start/cancel work from a new Overview warning action, and clear or replace diagnosis when the selected warning target changes.
- Extend the Overview warning row rendering with a `sparkles` action while keeping the Events tab call site action-free.
- Update docs to define the approved manual event diagnostic boundary alongside existing Pod diagnostics.
- Run focused tests first, then the quality gate.

**failure_behavior:** If Core reader/requester tests fail, stop before exposing the UI action. If UI build fails, revert UI wiring without changing existing Pod log streaming, Pod AI diagnosis, Settings, or refresh behavior.

**security_considerations:** This step sends user-approved Warning Event text to an external provider. It must bound and redact event messages, keep API keys in Keychain, show sanitized errors only, avoid Pod logs/Secrets/kubeconfig/raw JSON/full transcripts, and avoid automatic execution of AI suggestions.
