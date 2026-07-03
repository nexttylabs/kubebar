---
title: "feat: add manual AI Pod diagnostics"
type: feat
status: planned
date: 2026-07-02
origin: .imm/specs/2026-07-02-ai-pod-diagnostics.md
---

# feat: add manual AI Pod diagnostics

## Summary

- Summary: Add a contextual, manually triggered `AI Diagnose this Pod` action to the Pod Micro-Logs Drawer that rereads the last 50 Pod log lines, sends bounded redacted context to the configured AI Provider, and renders a transient Markdown diagnosis.

This plan implements the user-confirmed adjustment from a possible footer action to a Pod-context action. The feature deliberately avoids a global footer diagnosis button because the AI request is target-specific and may send Pod logs. AI output remains display/help behavior only.

## Current Slice

- Roadmap source: none
- Execution scope: Pod Micro-Logs Drawer AI action, finite `kubectl logs --tail=50` read boundary, Pod diagnostic prompt/request boundary, transient diagnosis UI state, provider error redaction, docs/tests
- Deferred phases: primary Warning Events diagnosis, footer shortcut menu, multi-container selection, previous-container logs, report persistence/history, chat UX, and auto-remediation are outside this plan
- This is not a global AI cluster diagnosis roadmap.

## Task

- Type: feat
- Scope: Pod Micro-Logs Drawer, AI provider request service, finite Pod log read, transient report rendering, docs/tests
- Owner: imm-work
- Verification: focused Swift tests, Swift build, and full Swift quality gate when practical

## Output Language

Spec and Plan prose are English. Code identifiers, schema fields, CLI commands, file paths, provider names, API names, enum cases, Markdown headings, and Immune-Brain fields remain literal.

## Origin

The user requested one-click `AI Lightning Diagnostics` and then confirmed this direction:

- Prefer a contextual `AI Diagnose this Pod` entry over a footer primary button.
- Allow sending the selected Pod's last 50 log lines to the configured AI Provider.
- Reread logs with `kubectl logs --tail=50` instead of using the current live drawer buffer.
- Never automatically execute AI-suggested `kubectl` commands.
- Provide safe failure-state recommendations.

No persisted Brainstorm manifest was created before this plan; the confirmed scope above is the closed input for this executable slice.

## Research

- `CONTEXT.md` defines `AI Diagnostic Assistant`, `AI Provider configuration`, `AI Provider API key`, `AI Pod diagnostic input`, and `Pod Micro-Logs Drawer`. This plan revises the earlier warning-only diagnostic boundary now that the user approved Pod log submission.
- `docs/architecture/runtime-invariants.md` already requires AI to remain display/help behavior only, API keys to stay in Keychain, Test Connection to send no Kubernetes data, and Pod logs to stay outside health evaluation.
- `KubebarCore/Services/AIProviderConnectionTester.swift` provides the provider-specific request and redacted-result pattern for OpenAI, Anthropic, Gemini, and OpenAI-compatible endpoints.
- `KubebarCore/Services/AIProviderCredentialStore.swift` and `Kubebar/Services/KeychainAIProviderCredentialStore.swift` own the Keychain-only credential boundary.
- `KubebarCore/Services/HTTPClient.swift` is the injectable HTTP boundary for provider requests.
- `KubebarCore/Services/PodLogStreamer.swift` owns app-context `kubectl logs --tail=100 -f`; its request shape is the closest pattern for a finite `--tail=50` read.
- `Kubebar/MenuBarViewModel.swift` owns Pod log drawer lifecycle, active app config, provider connection testing, and task cancellation. It is the correct owner for starting/cancelling the AI diagnostic request.
- `Kubebar/Views/MenuBarRootView.swift` owns `PodLogDrawerView`; `Kubebar/Views/PodLogWindowPresenter.swift` hosts it in the focusable log window.
- `KubebarCore/Models/MenuDisplayModel.swift` and `HealthEvaluator.swift` already prepare display-ready Pod rows and warning summaries; SwiftUI views must not infer health.
- Read-only planner research inspected AI provider boundaries and identified credential leakage, log PII, request-size, stale-data, and boundary isolation risks. A second read-only probe for Pod log UI returned no output, so the planner fell back to inline file inspection.

## Decisions

- Put the primary action in the Pod Micro-Logs Drawer toolbar, near search/copy, not in the menu footer.
- Ship Pod-level diagnostics only in this MVP; Warning Events can later deep-link to Pod diagnostics when a reliable Pod target exists.
- Add a finite Pod log reader boundary that uses `kubectl --context <context> logs --tail=50 -n <namespace> <pod>` and the same effective kubeconfig environment rules as other `kubectl` reads.
- Add a separate AI diagnostic requester instead of mixing diagnostic payloads into `AIProviderConnectionTester`.
- Reuse the existing AI Provider configuration, Keychain credential store, and HTTP client abstractions.
- Keep the generated report transient in `MenuBarViewModel` state; do not persist reports or logs.
- Redact obvious secrets from log payloads before provider submission and from all visible failure text.
- Render Markdown as readable text/code blocks enough for the MVP; commands are copyable by text selection/copy, not executed by Kubebar.
- Keep all AI diagnosis results outside `HealthEvaluator`, `MenuDisplayModel` health categories, Health State Shift Alerts, watchlist ordering, and menu bar icon state.

## Assumptions

- The selected Pod target from `PodLogTarget` is sufficient for this slice; container selection and previous-container logs remain deferred.
- `WarningEventDisplay` rows are acceptable as the latest 3 related warning summaries for the first version; exact event-to-Pod matching can be strengthened later.
- If warning rows or finite logs are unavailable, diagnosis can either fail safely or proceed with explicit unavailable text, depending on which boundary failed.
- Provider responses are plain text/Markdown; a full Markdown parser dependency is not required for the MVP.
- Focused tests can cover Core service behavior; app-target UI wiring is primarily build/quality-gate verified because current package tests target `KubebarCore` only.

## Planning Quality Gate Notes

- Contract surface: `CONTEXT.md`, `.imm/specs/2026-07-02-ai-pod-diagnostics.md`, `docs/architecture/runtime-invariants.md`, `KubebarCore/Services/AIProviderConnectionTester.swift`, new diagnostic requester/finite log reader services, `KubebarCore/Services/PodLogStreamer.swift`, `Kubebar/MenuBarViewModel.swift`, `Kubebar/Views/MenuBarRootView.swift`, `Kubebar/Views/PodLogWindowPresenter.swift`, and focused tests.
- Compatibility: no persisted config migration is needed; the feature uses existing AI Provider configuration and stores no diagnosis history.
- Interruption recovery: if service work compiles but UI wiring is incomplete, no user path should invoke the new request. If UI wiring fails, revert the app-target view/model changes while keeping or reverting Core tests coherently.
- Rollback path: revert the new services, ViewModel/UI wiring, docs/spec/plan/changelog, and tests. No Kubernetes resources or persisted cluster data are modified.
- Verification strength: request-construction tests must fail if logs are not bounded/redacted, if provider payload omits required Markdown sections, if credentials leak into visible errors, or if the finite log read uses the wrong context/kubeconfig.
- Scope discipline: this plan intentionally excludes global/footer diagnosis and auto-remediation; those are product expansions, not hidden MVP tasks.

## Devil's Advocate Audit

### Rollback resilience

The plan keeps AI diagnosis behind explicit UI and injectable boundaries. If provider-request tests fail, the UI can stay unexposed. If UI wiring fails, reverting `MenuBarViewModel` and Pod drawer view changes removes the feature without touching existing Settings/Test Connection. No step mutates Kubernetes resources.

### Verification vanity

Label-existence is not enough. Verification must inspect generated `kubectl` arguments, request bodies, redacted log payloads, safe failure messages, required Markdown instructions, and cancellation/empty-state behavior. The full quality gate confirms Xcode and SwiftPM surfaces compile with the new files.

### Spec dilution detection

The plan covers the user-approved changes: contextual Pod drawer placement, last 50 logs, fresh reread, no auto-execution, and safe failure states. It explicitly documents the privacy-boundary expansion from warning-only input to user-approved redacted Pod logs instead of silently preserving the old boundary.

## Scope Boundaries

- In scope: Pod drawer `AI Diagnose this Pod`, finite last-50 log reread, current Pod display status, latest warning summaries, redacted provider request, transient Markdown report, safe failures, docs/tests.
- Out of scope: menu-footer primary diagnosis, global cluster diagnosis, Warning Events primary diagnosis, automatic/background diagnosis, auto-executed fixes, Secret reads, kubeconfig transmission, full raw kubectl transcripts, raw cluster JSON, persistence/history, chat UX, previous-container logs, and multi-container selection.

## Deferred Work

- Add Warning Events row-level `sparkles` only when a reliable Pod target can be derived.
- Add a footer secondary menu only if users need a shortcut after a selected/open Pod concept exists.
- Add explicit multi-container and previous-container log diagnostics.
- Add a richer Markdown renderer or copy-code-block controls if the basic report surface is not enough.
- Add enterprise privacy docs after the first Pod-log diagnostic slice ships.

## Implementation Units

### Step 1

- Step ID: U1
- Result: The Pod Micro-Logs Drawer manually renders a safe AI diagnosis for its selected Pod.
- Verification: swift test --filter AIProviderConnectionTesterTests && swift test --filter PodLogStreamerTests && swift test --filter MenuDisplayModelTests && swift build && ./scripts/swift-quality-gate.sh local && rtk git diff --check
- Depends on: None
- Test scenarios: Pod AI action is only in the Pod log drawer; finite log request uses `--context`, `logs`, `--tail=50`, namespace, and pod name without `-f`; explicit kubeconfig paths flow into the finite log environment; missing provider model/key/base URL returns safe local failure; diagnostic request body includes Pod status, 3 warning summaries, redacted last 50 log lines, and required Markdown headings; obvious secrets in logs are redacted before submission; provider/network errors never expose API keys/Bearer tokens/raw response body; report state supports loading, success, retryable failure, unavailable logs, and empty logs; AI suggested commands remain text only and no mutation command is executed by Kubebar; docs preserve Health category independence
- Discovery cache: KubebarCore/Services/AIProviderConnectionTester.swift (provider request/redaction pattern); KubebarCore/Services/AIProviderCredentialStore.swift (Keychain protocol); KubebarCore/Services/HTTPClient.swift (provider HTTP boundary); KubebarCore/Services/PodLogStreamer.swift (kubectl logs context/kubeconfig pattern); Kubebar/MenuBarViewModel.swift (Pod drawer lifecycle and AI settings callbacks); Kubebar/Views/MenuBarRootView.swift (PodLogDrawerView); Kubebar/Views/PodLogWindowPresenter.swift (log window host); KubebarCore/Models/MenuDisplayModel.swift (display-ready warnings and Pod rows); docs/architecture/runtime-invariants.md (runtime safety contract); CONTEXT.md (canonical AI diagnostic vocabulary)

**Goal:** Deliver the full user-visible Pod AI diagnosis loop in one coherent feature.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14

**Dependencies:** None

**Files:**
- Modify: `CONTEXT.md`
- Modify: `docs/architecture/runtime-invariants.md`
- Add: `KubebarCore/Services/PodDiagnosticLogReader.swift`
- Add: `KubebarCore/Services/AIPodDiagnosticRequester.swift`
- Add or modify: `KubebarCore/Models/AIPodDiagnosis.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify: `Kubebar/Views/MenuBarRootView.swift`
- Modify: `Kubebar/Views/PodLogWindowPresenter.swift`
- Modify/Add: `KubebarTests/Services/PodLogStreamerTests.swift`
- Add: `KubebarTests/Services/AIPodDiagnosticRequesterTests.swift`
- Add: `changelog.d/ai-pod-diagnostics.added.md`

**Approach:**
- Add Core value types for Pod diagnostic context, warning summaries, report state, and diagnostic result.
- Add a finite `PodDiagnosticLogReader` using `CommandRunning` and `KubectlEnvironment` to read `kubectl logs --tail=50` without following.
- Add `AIPodDiagnosticRequester` that loads the provider API key from the credential store, validates model/base URL, redacts log context, constructs provider-specific requests, and returns Markdown text or safe errors.
- Thread a transient diagnosis state through `MenuBarViewModel`, start/cancel work from a new `diagnoseCurrentPodWithAI()` method, and reset diagnosis when the drawer target changes/closes.
- Extend `PodLogDrawerView` with a `sparkles` action, disclosure text, loading/error/success rendering, and no auto-execute controls.
- Update docs to replace the old warning-only future diagnostic boundary with the approved manual Pod log diagnostic boundary.
- Run focused tests first, then the quality gate.

**failure_behavior:** If the Core service tests fail, stop before exposing the UI action. If the UI build fails, revert UI wiring without changing existing Pod log streaming or AI Settings behavior.

**security_considerations:** This step sends user-approved Pod logs to an external provider. It must bound and redact logs, keep API keys in Keychain, show sanitized errors only, avoid Secrets/kubeconfig/raw JSON/full transcripts, and avoid automatic execution of AI suggestions.
