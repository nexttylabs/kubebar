---
title: "feat: configure AI Diagnostic Assistant provider settings"
type: feat
status: planned
date: 2026-07-01
origin: .imm/specs/2026-07-01-ai-diagnostic-assistant-settings.md
---

# feat: configure AI Diagnostic Assistant provider settings

## Summary

- Summary: Users can configure an AI provider, store its API key in Keychain, and manually test the connection without sending Kubernetes data.

Add an app-wide `AI Diagnostic Assistant` section to App Settings. The current executable slice saves non-secret AI Provider configuration, stores provider credentials in macOS Keychain, and exposes a manually triggered Test Connection. It deliberately does not implement automatic diagnosis or warning submission yet; it records that any later diagnostic payload is limited to user-approved warning text.

## Current Slice

- Roadmap source: none
- Execution scope: App Settings provider metadata, Keychain credential boundary, provider Test Connection service, safe feedback, and docs/tests for those behaviors
- Deferred phases: manual warning-text explanation, prompt UX, chat history, account/OAuth flows, cloud sync, advanced provider headers, and any deeper troubleshooting surface remain outside this plan
- This is not the full AI diagnosis roadmap; it is the secure configuration and connection-test slice.

## Task

- Type: feat
- Scope: AI Diagnostic Assistant settings, app config persistence, Keychain credentials, provider HTTP test boundary, Settings UI, and safety docs
- Owner: imm-work
- Verification: focused Swift tests, full Swift quality gate, and visible Settings smoke when practical
- Brainstorm manifest: BR-REQ-001; BR-REQ-002; BR-REQ-003; BR-REQ-004; BR-REQ-005; BR-REQ-006; BR-REQ-007; BR-REQ-008; BR-REQ-009; BR-REQ-010; BR-REQ-011; BR-REQ-012; BR-OUT-001; BR-OUT-002; BR-OUT-003; BR-OUT-004; BR-OUT-005; BR-DEC-001; BR-DEC-002; BR-DEC-003; BR-Q-001

## Output Language

Spec and Plan prose are English. Schema fields, commands, file paths, provider names, API names, enum cases, and Immune-Brain fields stay literal.

## Origin

The user requested configurable AI Provider support for Kubebar's Settings page and then confirmed the narrowed first version:

- `BR-Q-001`: `OpenAI-compatible` supports only Bearer API Key, Base URL, and Model ID; custom headers are not included.
- Test Connection is manual.
- The first executable slice saves configuration and tests the connection.
- Diagnostic input scope, when later implemented, is warning text only.
- API keys must be stored in Keychain.
- `Ollama` is removed and replaced by `OpenAI-compatible`.

## Brainstorm Manifest

- `BR-REQ-001`: Settings' fixed `App Settings tab` adds an `AI Diagnostic Assistant` section.
- `BR-REQ-002`: Provider choices are `OpenAI`, `Anthropic`, `Google Gemini`, and `OpenAI-compatible`.
- `BR-REQ-003`: Remove the originally proposed `Ollama` option.
- `BR-REQ-004`: Users can configure `Model ID`.
- `BR-REQ-005`: `OpenAI-compatible` supports a configurable `Base URL`.
- `BR-REQ-006`: API keys must be saved in macOS Keychain, not normal persisted config.
- `BR-REQ-007`: Saved configuration supports manual `Test Connection`.
- `BR-REQ-008`: Test Connection must not expose API keys, complete response bodies, raw requests, or token-like text.
- `BR-REQ-009`: AI actions are manually triggered.
- `BR-REQ-010`: The first diagnostic input boundary is warning text only.
- `BR-REQ-011`: AI output must not affect `HealthEvaluator` or menu health categories.
- `BR-REQ-012`: `OpenAI-compatible` supports only Bearer API Key, Base URL, and Model ID; no custom headers.
- `BR-OUT-001`: No background automatic diagnosis.
- `BR-OUT-002`: No Pod log submission.
- `BR-OUT-003`: No Kubernetes Secret reads or transmission.
- `BR-OUT-004`: No complete `kubectl` output or raw cluster JSON submission.
- `BR-OUT-005`: No chat history, account system, OAuth, or cloud sync.
- `BR-DEC-001`: AI Provider configuration is app-wide, not per-context watchlist state.
- `BR-DEC-002`: Network calls go through injectable service boundaries; UI does not call provider APIs directly.
- `BR-DEC-003`: AI results are auxiliary explanations, never health-category inputs.
- `BR-Q-001`: Whether `OpenAI-compatible` supports custom headers.

## Brainstorm Trace

| Item | Status | Target | Reason |
| --- | --- | --- | --- |
| BR-REQ-001 | covered_by_step | U3 | U3 adds the App Settings UI section. |
| BR-REQ-002 | covered_by_step | U1, U2, U3 | U1 models choices, U2 tests provider requests, and U3 exposes choices. |
| BR-REQ-003 | covered_by_step | U1, U3 | U1 excludes `Ollama` from the model and U3 excludes it from the picker. |
| BR-REQ-004 | covered_by_step | U1, U3 | U1 persists `Model ID`; U3 renders editing. |
| BR-REQ-005 | covered_by_step | U1, U2, U3 | U1 stores the optional base URL, U2 validates request construction, and U3 renders it only when relevant. |
| BR-REQ-006 | covered_by_step | U2, U3 | U2 creates the Keychain credential boundary; U3 wires Settings save through it. |
| BR-REQ-007 | covered_by_step | U2, U3 | U2 creates Test Connection service behavior; U3 exposes the manual action. |
| BR-REQ-008 | covered_by_step | U2, U3 | U2 owns redaction tests and U3 shows only safe result text. |
| BR-REQ-009 | covered_by_step | U3 | Test Connection is button-triggered; future diagnostics remain documented as manual-only. |
| BR-REQ-010 | deferred | Deferred Work | This plan does not implement diagnosis; it preserves the accepted warning-text-only boundary for a later diagnostic plan. |
| BR-REQ-011 | captured_as_decision | Decisions | The plan explicitly keeps AI outside `HealthEvaluator` and health-category ownership. |
| BR-REQ-012 | covered_by_step | U1, U2, U3 | U1 models the limited contract, U2 tests Bearer request construction, and U3 avoids custom-header UI. |
| BR-OUT-001 | out_of_scope | Scope Boundaries | No scheduled or background AI work is introduced. |
| BR-OUT-002 | out_of_scope | Scope Boundaries | Pod logs remain outside AI submission. |
| BR-OUT-003 | out_of_scope | Scope Boundaries | Kubebar still does not query or send Kubernetes Secrets. |
| BR-OUT-004 | out_of_scope | Scope Boundaries | Test Connection sends no cluster data; diagnostic data submission is deferred. |
| BR-OUT-005 | out_of_scope | Scope Boundaries | The slice has no accounts, OAuth, cloud sync, or chat history. |
| BR-DEC-001 | covered_by_step | U1, U3 | AI config is stored as global app Settings metadata. |
| BR-DEC-002 | covered_by_step | U2 | Provider calls are behind injectable credential and HTTP/service protocols. |
| BR-DEC-003 | captured_as_decision | Decisions | AI output is display-only and not part of health evaluation. |
| BR-Q-001 | resolved_as_assumption | Decisions | User confirmed no custom headers for `OpenAI-compatible` first version. |

## Research

- `CONTEXT.md` now defines `AI Diagnostic Assistant`, `AI Provider configuration`, `AI Provider API key`, `OpenAI-compatible provider`, and `Warning text diagnostic input`.
- `docs/architecture/runtime-invariants.md` requires external reads through injectable boundaries, safe display text, no raw command transcripts, and no Kubernetes Secret reads.
- `AGENTS.md` treats secrets, config loading, persistence, and public/network-facing APIs as high-risk changes.
- `KubebarCore/Services/AppConfigStore.swift` persists selected context, watchlists, refresh cadence, Health State Shift Alerts, and kubeconfig paths with backward-compatible decoding.
- `KubebarCore/Models/SetupFlowState.swift` owns Settings editing state, including App Settings and per-context tabs.
- `KubebarCore/Models/MenuRuntimeState.swift` bridges saved `AppConfig`, Settings editing state, completed config, and unsaved-change detection.
- `Kubebar/Views/SetupView.swift` renders App Settings sections and context tab content.
- `Kubebar/Views/SettingsRootView.swift` wraps `SetupView` and routes Settings callbacks to `MenuBarViewModel`.
- `Kubebar/MenuBarViewModel.swift` owns Settings preparation, save, and app-target service injection.
- `KubebarCore/Services/CommandRunner.swift`, `KubebarCore/Services/KubectlClusterReader.swift`, and `KubebarCore/Services/WatchTargetCatalog.swift` show the preferred injectable boundary pattern.
- `docs/solutions/app-settings/start-at-login-boundary-2026-05-19.md` shows how native macOS side effects stay behind an app-target boundary and fake-friendly Core abstractions.
- `docs/solutions/architecture/per-context-watchlists-active-context-2026-06-03.md` shows the App Settings/global-state pattern and the need to preserve per-context watchlists.
- Search found no existing Keychain, `SecItem`, or AI provider client code.
- Current provider docs indicate direct Anthropic requests use `x-api-key` plus `anthropic-version`, Gemini supports OpenAI-compatible endpoints and direct Gemini APIs, and OpenAI-compatible endpoints commonly use `Authorization: Bearer`; implementation should isolate these details behind provider-specific request builders and tests.
- Planner research dispatch used two read-only agents because the task spans Settings/config and secrets/network domains. Their outputs identified state-sync risks, Keychain redaction risks, and focused verification implications.

## Decisions

- Model AI Provider configuration as a small app-wide value type in `KubebarCore`, separate from any secret-bearing value.
- Persist provider kind, model ID, and `OpenAI-compatible` base URL through `AppConfig`; do not encode API keys.
- Default older configs to an unconfigured AI Provider state so existing users are not forced into AI setup.
- Store provider API keys through an injectable credential-store protocol with a production Keychain adapter and in-memory fakes for tests.
- Build Test Connection through an injectable service boundary that owns credential lookup, URLRequest construction, provider-specific headers, HTTP execution, and redaction.
- Keep SwiftUI views thin: views render fields/buttons and callbacks, but do not read Keychain, construct requests, or inspect raw provider responses.
- Make Test Connection manual and send only a minimal provider-specific probe; no Kubernetes data is included.
- Keep `OpenAI-compatible` limited to Bearer API Key, Base URL, and Model ID. Do not add custom headers.
- Preserve AI as display/help behavior only; `HealthEvaluator`, `MenuDisplayModel` health categories, and menu bar icon states remain unchanged.

## Assumptions

- One API key slot per provider kind is sufficient for this slice; `OpenAI-compatible` uses its own credential slot.
- Empty model ID, missing API key, or missing `OpenAI-compatible` base URL should produce safe local validation feedback instead of attempting a network request.
- Provider-specific advanced settings such as organization IDs, project IDs, temperature, custom headers, or alternate auth flows are not required for Test Connection.
- Production Keychain access can be implemented in the app target while Core owns protocols and pure testable behavior.
- Visible app smoke is useful but not the primary verification signal because automated UI tests are not configured.

## Planning Quality Gate Notes

- Contract surface: `CONTEXT.md`, `.imm/specs/2026-07-01-ai-diagnostic-assistant-settings.md`, `docs/architecture/runtime-invariants.md`, `AppConfig`, `SetupFlowState`, `MenuRuntimeState`, `SetupView`, `SettingsRootView`, `MenuBarViewModel`, new AI provider/credential/test service types, app-target Keychain adapter, provider tests, Settings state tests, and quality-gate scripts.
- Compatibility: older `config.json` files must decode with a default AI Provider configuration and no credential requirement. No migration prompt is allowed.
- Interruption recovery: after U1, config metadata can exist but no provider call is exposed. After U2, service tests can pass without UI exposure. After U3, users can configure and test connections; failure feedback remains safe.
- Rollback path: revert the files touched by the failed step plus related tests/docs. Deleting the AI config field from a partially written local config must fall back to defaults; Keychain entries should be namespaced so they can be deleted by the credential-store boundary if a later cleanup is needed.
- Verification strength: use Codable tests, Settings state tests, fake credential-store tests, fake HTTP request-construction tests, redaction tests, full Swift quality gate, and visible Settings smoke instead of label-only checks.
- Brainstorm traceability: every `BR-*` item is mapped above, including the resolved `BR-Q-001`.
- Acceptance scope discipline: current acceptance proves configuration and Test Connection only; warning-text diagnosis is deferred and non-executable in this plan.

## Devil's Advocate Audit

### Rollback resilience

The plan separates metadata persistence, credential/provider service boundaries, and UI exposure. If U1 fails, revert the config/model tests without touching Keychain or network code. If U2 fails, the unexposed service boundary can be reverted independently. If U3 fails, UI wiring can be reverted while leaving tested Core service behavior intact. No step mutates Kubernetes resources or reads Kubernetes Secrets.

### Verification vanity

A Settings label existing is not enough. U1 must fail if API keys can be encoded into `AppConfig` or if old configs no longer decode. U2 must fail if a request leaks credentials, skips the provider-specific auth contract, includes Kubernetes data, or surfaces raw secret-bearing error text. U3 must fail if the UI triggers provider calls without explicit user action or if the Settings save path drops provider metadata or credentials.

### Spec dilution detection

The plan covers all confirmed provider choices, removes `Ollama`, stores secrets in Keychain, supports Test Connection, and preserves the manual/warning-only diagnostic boundary. It intentionally defers actual warning explanation because the user confirmed the first executable work as configuration plus Test Connection; that deferral is mapped in Brainstorm Trace rather than silently omitted.

## Scope Boundaries

- In scope: app-wide AI Provider metadata, Keychain credential storage boundary, provider-specific Test Connection, safe result text, Settings UI controls, docs updates, and focused tests.
- Out of scope: Ollama, automatic diagnosis, Pod logs, Kubernetes Secrets, complete `kubectl` output, raw cluster JSON, warning explanation execution, chat history, account system, OAuth, cloud sync, custom headers, and health-category changes.

## Deferred Work

- Manual AI explanation for user-approved warning summary text.
- A dedicated diagnostics result surface, if warning explanation needs more than a Settings/Test Connection message.
- Provider-specific advanced settings beyond model/base URL/API key.
- Credential rotation or reset UX beyond replacing/deleting the currently selected provider key.
- Optional docs for enterprise privacy posture after the diagnostic submission slice exists.

## Implementation Units

### Step 1

- Step ID: U1
- Result: AI Provider configuration metadata persists through Settings state without storing API keys.
- Verification: swift test --filter AppConfigTests && swift test --filter AppConfigStoreTests && swift test --filter SetupFlowStateTests && swift test --filter MenuRuntimeStateTests && rtk git diff --check
- Depends on: None
- Test scenarios: older configs decode with default AI Provider configuration; provider kind/model/base URL round-trip through AppConfig; AppConfig encoding does not contain sentinel API keys; selecting context preserves app-wide AI Provider configuration; preparing Settings exposes saved AI Provider configuration; completed config preserves AI Provider configuration and existing per-context watchlists
- Discovery cache: KubebarCore/Services/AppConfigStore.swift (persisted config shape); KubebarCore/Models/SetupFlowState.swift (Settings editing state); KubebarCore/Models/MenuRuntimeState.swift (completed config and unsaved-change detection); KubebarTests/Models/AppConfigTests.swift (global config behavior); KubebarTests/Services/AppConfigStoreTests.swift (Codable compatibility); KubebarTests/Models/SetupFlowStateTests.swift (Settings state behavior); KubebarTests/Models/MenuRuntimeStateTests.swift (completed config behavior)

**Goal:** Add durable non-secret AI Provider configuration while preserving existing config compatibility and Settings behavior.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R1, R2, R3, R4, R5, R6, R7, R13

**Dependencies:** None

**Files:**
- Modify: `KubebarCore/Services/AppConfigStore.swift`
- Modify or add: `KubebarCore/Models/AIDiagnosticAssistantConfig.swift`
- Modify: `KubebarCore/Models/SetupFlowState.swift`
- Modify: `KubebarCore/Models/MenuRuntimeState.swift`
- Modify: `KubebarTests/Models/AppConfigTests.swift`
- Modify: `KubebarTests/Services/AppConfigStoreTests.swift`
- Modify: `KubebarTests/Models/SetupFlowStateTests.swift`
- Modify: `KubebarTests/Models/MenuRuntimeStateTests.swift`

**Approach:**
- Add a small Codable/Equatable/Sendable model for provider kind, model ID, and optional OpenAI-compatible base URL.
- Add backward-compatible `AppConfig` decoding with a safe default AI Provider configuration.
- Keep API key values out of the model entirely; tests should encode a sentinel key elsewhere and assert it never appears in config JSON.
- Thread the value through `SetupFlowState`, `MenuRuntimeState.setupState(from:)`, `completedConfig()`, and unsaved-change detection.
- Keep AI Provider configuration app-wide and independent of per-context watchlists.

**failure_behavior:** If compatibility tests fail, stop before adding credential or network behavior. Existing user configs must remain loadable before later steps can proceed.

**security_considerations:** This step must prove the persisted model has no API-key field and no encoded sentinel secret.

### Step 2

- Step ID: U2
- Result: AI Provider Test Connection uses injectable redacted credential boundaries.
- Verification: swift test --filter AIDiagnosticAssistant && swift test --filter AIProviderCredential && swift test --filter AIProviderConnection && swift build && rtk git diff --check
- Depends on: 1
- Test scenarios: missing API key returns safe local failure; replacing a key updates only the credential store; AppConfigStore never receives a secret-bearing model; OpenAI request uses Authorization Bearer and minimal body; Anthropic request uses provider-specific key/version headers; Gemini request avoids putting the key in visible result text; OpenAI-compatible request uses configured Base URL with Bearer auth and no custom headers; network/provider errors containing a sentinel key or Bearer token are redacted; Test Connection sends no warning text, Pod logs, kubeconfig, raw kubectl output, or cluster JSON
- Discovery cache: KubebarCore/Services/CommandRunner.swift (injectable boundary pattern); KubebarCore/Services/KubectlClusterReader.swift (safe failure mapping pattern); KubebarCore/Services/StartAtLoginSettingsCoordinator.swift (native side-effect abstraction pattern); Kubebar/Services/LoginItemController.swift (app-target macOS API wrapper pattern); KubebarTests/Services/StartAtLoginSettingsCoordinatorTests.swift (fake-controller tests); KubebarTests/Services/KubectlClusterReaderTests.swift (request/failure tests)

**Goal:** Make credential handling and provider probing testable without leaking secrets or performing real network calls in tests.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R2, R5, R6, R7, R8, R9, R10, R11, R13

**Dependencies:** U1

**Files:**
- Add: `KubebarCore/Services/AIProviderCredentialStore.swift`
- Add: `KubebarCore/Services/AIProviderConnectionTester.swift`
- Add: `KubebarCore/Services/HTTPClient.swift`
- Add or modify: app-target Keychain adapter under `Kubebar/Services/`
- Add or modify: `KubebarTests/Services/AIProviderCredentialStoreTests.swift`
- Add or modify: `KubebarTests/Services/AIProviderConnectionTesterTests.swift`

**Approach:**
- Define credential-store and HTTP-client protocols in Core with fake implementations in tests.
- Put production Keychain access behind an app-target adapter using macOS Security APIs.
- Build provider-specific request builders inside the service layer, not in SwiftUI views.
- Keep Test Connection payload minimal and unrelated to Kubernetes data.
- Centralize redaction so thrown errors, HTTP bodies, and transport descriptions cannot surface API keys or Bearer tokens.

**parallel_probes:**
- scope: `KubebarCore/Services/CommandRunner.swift`, `KubebarCore/Services/KubectlClusterReader.swift`; output: boundary and safe-failure conventions to preserve; readonly: true
- scope: `Kubebar/Services/LoginItemController.swift`, `KubebarCore/Services/StartAtLoginSettingsCoordinator.swift`; output: native macOS adapter and fake-test conventions; readonly: true
- scope: provider API docs and tests; output: minimal request contract per provider without adding custom headers; readonly: true

**failure_behavior:** If Keychain or redaction tests fail, do not wire UI actions. The feature must remain unreachable until credentials and safe errors are proven.

**security_considerations:** This is the highest-risk step. It touches secrets and network-facing behavior, so all user-visible result strings must be sanitized and tests must include sentinel secrets.

### Step 3

- Step ID: U3
- Result: App Settings exposes AI Diagnostic Assistant configuration with manual Test Connection feedback.
- Verification: swift test --filter SetupFlowStateTests && swift test --filter MenuRuntimeStateTests && swift test --filter AIDiagnosticAssistant && /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local && rtk git diff --check
- Depends on: 2
- Test scenarios: App Settings shows AI Diagnostic Assistant controls; provider picker excludes Ollama; OpenAI-compatible reveals Base URL and does not reveal custom-header fields; saving Settings persists provider metadata and saves API key through credential store only; Test Connection is button-triggered and not automatic on open/save; success and failure messages are safe; missing key/model/base URL shows local validation feedback; existing Start at Login, Health State Shift Alerts, kubeconfig paths, and per-context watchlists still save correctly; runtime docs state AI does not affect Health category and diagnostic input is manually approved warning text only
- Discovery cache: Kubebar/Views/SetupView.swift (App Settings UI); Kubebar/Views/SettingsRootView.swift (Settings wrapper callbacks); Kubebar/MenuBarViewModel.swift (Settings save/test action boundary); KubebarCore/Models/MenuRuntimeState.swift (runtime state publication); docs/architecture/runtime-invariants.md (runtime safety rules); scripts/swift-quality-gate.sh (full verification)

**Goal:** Give users a visible, safe Settings workflow for provider configuration and Test Connection.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R1, R2, R3, R4, R5, R7, R8, R9, R10, R11, R13

**Dependencies:** U2

**Files:**
- Modify: `Kubebar/Views/SetupView.swift`
- Modify: `Kubebar/Views/SettingsRootView.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify: `KubebarCore/Models/SetupFlowState.swift`
- Modify: `KubebarCore/Models/MenuRuntimeState.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Modify or add: relevant Settings/ViewModel tests where feasible

**Approach:**
- Add a dedicated `AI Diagnostic Assistant` section to App Settings using existing Settings section patterns.
- Render provider picker, model text field, OpenAI-compatible base URL field, secure API key entry, credential delete/replace affordance if needed, and a `Test Connection` button.
- Route field updates and Test Connection through `MenuBarViewModel`; publish safe state changes back through `MenuRuntimeState`.
- Ensure opening Settings and saving Settings do not automatically call providers.
- Update runtime invariants to preserve no-health-category-input and warning-text-only diagnostic boundaries.
- Run the full quality gate and, when practical, launch the app to smoke-check the Settings section and manual Test Connection affordance.

**failure_behavior:** If UI wiring fails, leave provider settings inaccessible rather than exposing a button that can leak secrets or make unintended network calls.

**security_considerations:** The UI must not display raw API keys after save, raw HTTP bodies, full requests, or token-like provider errors. It must clearly separate Test Connection from any Kubernetes diagnostic submission.

## Verification Approach

- Run `/Users/derek/workspaces/agent-skills/plugins/immune-brain/bin/imm-plan docs/plans/2026-07-01-001-feat-ai-diagnostic-assistant-settings-plan.md --json` before execution handoff.
- U1 uses Codable and state tests to prove compatibility and non-secret persistence.
- U2 uses fake credential and HTTP clients to prove provider request construction, manual Test Connection behavior, and redaction without real network calls.
- U3 uses focused state/UI wiring tests plus the full `./scripts/swift-quality-gate.sh local` gate.
- A visible app smoke with `./scripts/compile-and-run.sh` is recommended when practical to confirm App Settings shows the section and Test Connection remains manual.
