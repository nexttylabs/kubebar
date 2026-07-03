---
title: "feat: customize AI diagnostic prompts"
type: feat
status: planned
date: 2026-07-03
origin: .imm/specs/2026-07-03-ai-diagnostic-prompt-customization.md
---

# feat: customize AI diagnostic prompts

## Summary

- Summary: Add per-surface AI diagnostic prompt customization in `AI Assistant` Settings so users can edit Pod and Warning Event diagnosis instructions from built-in defaults, reset either surface to default, and keep immutable safety/data boundaries in code.

This plan implements the user-confirmed recommendation: Pod and Warning Event diagnosis each get a separate editable prompt, reset clears the override back to the built-in default, and the safety/system prompt remains non-editable.

## Current Slice

- Roadmap source: none
- Execution scope: `AI Assistant` Settings prompt editors, per-surface prompt override config, default/reset behavior, provider request prompt rendering, docs/tests
- Deferred phases: full prompt template language, provider-specific prompt tuning, prompt import/export, history, chat UX, cloud sync, global cluster diagnosis, and auto-remediation are outside this plan
- This is not a global AI assistant customization roadmap.

## Task

- Type: feat
- Scope: AI Diagnostic Assistant prompt settings, local config persistence, Pod/Event diagnostic requester prompt composition, docs/tests
- Owner: imm-work
- Verification: focused Swift tests, Swift build, and full Swift quality gate when practical

## Output Language

Spec and Plan prose are English. Code identifiers, schema fields, CLI commands, file paths, provider names, API names, enum cases, Markdown headings, and Immune-Brain fields remain literal.

## Origin

The user requested support for custom prompts: users should be able to modify a prompt based on Kubebar's default prompt and reset it to the default prompt. The preceding brainstorm recommended this exact product direction, and the user confirmed: proceed with the recommendation.

## Brainstorm manifest

- `BR-REQ-001`: Support custom prompt instructions based on the built-in default prompt.
- `BR-REQ-002`: Support resetting customized prompt instructions to the built-in default.
- `BR-REQ-003`: Provide separate prompt customization for `AI Pod diagnosis` and `AI Event diagnosis`.
- `BR-REQ-004`: Preserve immutable safety/system instructions that users cannot override.
- `BR-REQ-005`: Persist prompt overrides as non-secret local app configuration while keeping API keys Keychain-only.
- `BR-REQ-006`: Existing configs without prompt fields must continue to decode and use defaults.
- `BR-REQ-007`: Prompt customization must not expand the existing Pod/Event diagnostic data boundaries or affect Health category.
- `BR-OUT-001`: Do not add a full prompt template language or prompt variables UI in this slice.
- `BR-OUT-002`: Do not add global cluster diagnosis, chat/history, import/export, cloud sync, or auto-remediation.
- `BR-DEC-001`: Use per-surface prompt overrides instead of one global prompt.
- `BR-DEC-002`: Reset removes the custom override so future built-in default updates remain effective.
- `BR-DEC-003`: The user-editable text controls diagnostic instructions only; code still attaches structured context and fixed safety instructions.

## Brainstorm Trace

| Item | Status | Plan coverage |
| --- | --- | --- |
| `BR-REQ-001` | covered_by_step | Step 1 adds editable default-backed prompt instructions in `AI Assistant` Settings. |
| `BR-REQ-002` | covered_by_step | Step 1 adds per-surface reset behavior that clears overrides. |
| `BR-REQ-003` | covered_by_step | Step 1 stores and renders separate Pod and Event prompt overrides. |
| `BR-REQ-004` | covered_by_step | Step 1 keeps the requester safety/system prompt code-owned and non-editable. |
| `BR-REQ-005` | covered_by_step | Step 1 persists prompt overrides in `AppConfig` and leaves credentials in Keychain. |
| `BR-REQ-006` | covered_by_step | Step 1 includes config decode/default fallback tests. |
| `BR-REQ-007` | covered_by_step | Step 1 updates requesters without changing submitted diagnostic data or health evaluation. |
| `BR-OUT-001` | out_of_scope | A full template language is excluded to keep this slice low-risk and bounded. |
| `BR-OUT-002` | out_of_scope | These are broader AI roadmap items and are not needed for prompt reset/customization. |
| `BR-DEC-001` | captured_as_decision | Separate prompt surfaces avoid mixing Pod logs and Warning Event diagnosis instructions. |
| `BR-DEC-002` | captured_as_decision | Reset clears the override rather than saving a copy of the default. |
| `BR-DEC-003` | captured_as_decision | The editable prompt is an instruction override; structured context and safety stay code-owned. |

## Research

- `CONTEXT.md` defines `AI Diagnostic Assistant`, `AI Provider configuration`, `AI Provider API key`, `AI Pod diagnostic input`, `AI Event diagnostic input`, and the app-owned context/kubeconfig boundaries.
- `docs/architecture/runtime-invariants.md` requires AI diagnosis to remain display/help behavior only, not affect Health category, keep API keys in Keychain, avoid Secrets/kubeconfig/raw transcripts/raw JSON, and never auto-execute AI suggestions.
- `.imm/memory/current_iteration.json` shows the Pod and Event diagnostic plans are closed, so prompt customization should be a new executable slice rather than an append to a completed plan.
- `KubebarCore/Models/AIDiagnosticAssistantConfig.swift` currently stores provider/model/base URL only; it is the natural place for non-secret prompt override fields and default/effective prompt helpers.
- `KubebarCore/Services/AppConfigStore.swift`, `MenuRuntimeState.swift`, and `SetupFlowState.swift` compare and round-trip `AIDiagnosticAssistantConfig`, so prompt override fields must participate in save/change detection.
- `Kubebar/Views/SetupView.swift` owns the `AI Assistant` Settings page and currently exposes provider, model, base URL, API key, and Test Connection controls.
- `KubebarCore/Services/AIPodDiagnosticRequester.swift` and `AIEventDiagnosticRequester.swift` own provider request body construction and currently contain the built-in prompt strings.
- `KubebarTests/Services/AIPodDiagnosticRequesterTests.swift`, `AIEventDiagnosticRequesterTests.swift`, `KubebarTests/Models/AppConfigTests.swift`, `SetupFlowStateTests.swift`, and `MenuRuntimeStateTests.swift` are the focused test surfaces for prompt rendering and config behavior.
- `docs/solutions/architecture/ai-event-diagnostics-overview-entry-2026-07-02.md` reinforces that future AI surfaces should keep explicit context/data boundaries rather than letting UI or prompts broaden what gets diagnosed.

## Decisions

- Add Pod and Event prompt override fields to `AIDiagnosticAssistantConfig` or a small nested value type owned by that config.
- Treat nil, empty, or whitespace-only override text as "use the built-in default".
- Expose Settings editors that display the effective prompt text so the user starts from the default prompt even when no override is saved.
- Make `Reset to default` clear the stored override for the selected surface.
- Keep `systemPrompt`/safety instructions in requester code and non-editable.
- Keep structured Pod/Event diagnostic context generation in code and attach it to the user-editable instruction text so custom prompts cannot remove bounds, redaction, or the no-auto-execute disclosure.
- Do not send custom prompts through `AIProviderConnectionTester`; Test Connection stays a provider ping.
- Update docs to define custom prompt behavior as non-secret AI Provider configuration and preserve health-category independence.

## Assumptions

- TextEditor-based settings controls are acceptable for this slice; no advanced prompt-diff UI is needed.
- Persisting prompt overrides in local config is acceptable because prompt text is user-authored non-secret configuration. The UI should not imply it is a secret field.
- The built-in default prompt instructions can be split from the code-owned structured context blocks without changing the diagnostic data included in requests.
- Focused Core tests can prove request-body behavior; Settings UI is build/quality-gate verified unless existing app-target UI tests are found during execution.

## Planning Quality Gate Notes

- Contract surface: `.imm/specs/2026-07-03-ai-diagnostic-prompt-customization.md`, this Plan, `CONTEXT.md`, `docs/architecture/runtime-invariants.md`, `KubebarCore/Models/AIDiagnosticAssistantConfig.swift`, `AppConfigStore.swift`, `SetupFlowState.swift`, `MenuRuntimeState.swift`, `Kubebar/Views/SetupView.swift`, `AIPodDiagnosticRequester.swift`, `AIEventDiagnosticRequester.swift`, and focused tests.
- Compatibility: existing config files must decode through optional/default prompt override fields. Reset must remove overrides rather than requiring config migration. API key storage remains unchanged.
- Interruption recovery: if model/config tests pass but requester/UI work is incomplete, prompt override fields should either remain unused or be reverted coherently before exposing UI. A later `imm-work` run should continue from failing focused tests, not from partial UI state.
- Rollback path: revert the prompt config/model changes, requester prompt rendering changes, Settings UI additions, docs/spec/plan/changelog, and focused tests. No Kubernetes resources or Keychain entries are modified by the feature itself.
- Verification strength: tests must inspect serialized config/default fallback and actual provider request bodies, not only check that Settings labels exist. The quality gate confirms Xcode and SwiftPM surfaces compile.
- Brainstorm traceability: every `BR-*` item is mapped in `Brainstorm Trace`; there are no open `BR-Q-*` items.

## Devil's Advocate Audit

### Rollback resilience

The plan keeps prompt customization in non-secret config and request composition. If requester tests fail, the Settings UI can remain unexposed or the config fields can be reverted without changing existing provider credentials, Pod log reads, Warning Event reads, or health evaluation. Reset is a local config operation only.

### Verification vanity

A visible text editor or label would be vanity evidence. Verification must prove default fallback, custom override persistence, reset clearing semantics, prompt inclusion in provider request bodies, fixed safety/system prompt preservation, bounded Pod/Event context preservation, and unchanged Test Connection behavior.

### Spec dilution detection

The plan covers the confirmed recommendation: per-surface customization, default-backed editing, reset-to-default, and non-editable safety prompt. It explicitly excludes a full template language and broader AI roadmap work instead of silently narrowing the request to a single hard-coded override.

## Scope Boundaries

- In scope: Pod/Event prompt override fields, effective default helpers, Settings editors, per-surface reset, requester prompt composition, config/default tests, request-body tests, docs/tests.
- Out of scope: user-editable system prompt, prompt variables UI, global diagnosis, Events tab diagnosis expansion, chat/history, auto-remediation, custom headers, provider tuning, import/export, cloud sync, and any expansion of diagnostic payload data.

## Deferred Work

- Add a richer prompt template editor with variables only if users need explicit insertion controls after this MVP.
- Add import/export or team-managed prompt presets only after local prompt overrides are validated in usage.
- Add provider-specific output controls or model parameters only under a separate AI settings plan.

## Implementation Units

### Step 1

- Step ID: U1
- Result: `AI Assistant` Settings supports safe prompt customization/reset for Pod/Event diagnosis.
- Verification: swift test --filter AIPodDiagnosticRequesterTests && swift test --filter AIEventDiagnosticRequesterTests && swift test --filter AppConfigTests && swift test --filter SetupFlowStateTests && swift test --filter MenuRuntimeStateTests && swift test --filter AIProviderConnectionTesterTests && swift build && ./scripts/swift-quality-gate.sh local && rtk git diff --check
- Depends on: None
- Test scenarios: existing configs without prompt fields decode and use defaults; saving config round-trips custom Pod and Event prompt overrides without API keys; blank custom prompt falls back to built-in default; reset clears a surface override rather than saving default text; Settings change detection includes prompt overrides; Pod diagnostic request body includes custom Pod prompt instructions plus fixed safety prompt, bounded redacted last-50 logs, and no-auto-execute disclosure; Event diagnostic request body includes custom Event prompt instructions plus fixed safety prompt, latest-5 matching events, and no Pod logs; Test Connection sends no custom prompt or Kubernetes data; docs preserve Health category independence
- Discovery cache: KubebarCore/Models/AIDiagnosticAssistantConfig.swift (prompt override config and defaults); KubebarCore/Models/AIDiagnosticAssistantState.swift (Settings editing state helper surface); KubebarCore/Models/SetupFlowState.swift (Settings mutation methods); KubebarCore/Models/MenuRuntimeState.swift (config change detection); KubebarCore/Services/AppConfigStore.swift (config encode/decode compatibility); KubebarCore/Services/AIPodDiagnosticRequester.swift (Pod prompt request composition); KubebarCore/Services/AIEventDiagnosticRequester.swift (Event prompt request composition); KubebarCore/Services/AIProviderConnectionTester.swift (unchanged Test Connection boundary); Kubebar/Views/SetupView.swift (`AI Assistant` Settings UI); KubebarTests/Models/AppConfigTests.swift (config compatibility tests); KubebarTests/Models/SetupFlowStateTests.swift (Settings mutation tests); KubebarTests/Models/MenuRuntimeStateTests.swift (change detection tests); KubebarTests/Services/AIPodDiagnosticRequesterTests.swift (Pod request-body tests); KubebarTests/Services/AIEventDiagnosticRequesterTests.swift (Event request-body tests); docs/architecture/runtime-invariants.md (runtime safety contract); CONTEXT.md (canonical AI diagnostic vocabulary)

**Goal:** Deliver the full user-visible prompt customization/reset loop for the two existing manual AI diagnosis surfaces.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12

**Dependencies:** None

**Discovery cache:**
- `KubebarCore/Models/AIDiagnosticAssistantConfig.swift` (prompt override config and defaults)
- `KubebarCore/Models/AIDiagnosticAssistantState.swift` (Settings editing state helper surface)
- `KubebarCore/Models/SetupFlowState.swift` (Settings mutation methods)
- `KubebarCore/Models/MenuRuntimeState.swift` (config change detection)
- `KubebarCore/Services/AppConfigStore.swift` (config encode/decode compatibility)
- `KubebarCore/Services/AIPodDiagnosticRequester.swift` (Pod prompt request composition)
- `KubebarCore/Services/AIEventDiagnosticRequester.swift` (Event prompt request composition)
- `KubebarCore/Services/AIProviderConnectionTester.swift` (unchanged Test Connection boundary)
- `Kubebar/Views/SetupView.swift` (`AI Assistant` Settings UI)
- `KubebarTests/Models/AppConfigTests.swift` (config compatibility tests)
- `KubebarTests/Models/SetupFlowStateTests.swift` (Settings mutation tests)
- `KubebarTests/Models/MenuRuntimeStateTests.swift` (change detection tests)
- `KubebarTests/Services/AIPodDiagnosticRequesterTests.swift` (Pod request-body tests)
- `KubebarTests/Services/AIEventDiagnosticRequesterTests.swift` (Event request-body tests)
- `docs/architecture/runtime-invariants.md` (runtime safety contract)
- `CONTEXT.md` (canonical AI diagnostic vocabulary)

**Parallel probes:**
- Probe 1: scope `KubebarCore/Models/AIDiagnosticAssistantConfig.swift`, `AppConfigStore.swift`, `SetupFlowState.swift`, `MenuRuntimeState.swift`, and model tests; output concise config/default/reset notes; readonly true.
- Probe 2: scope `AIPodDiagnosticRequester.swift`, `AIEventDiagnosticRequester.swift`, `AIProviderConnectionTester.swift`, and requester tests; output concise prompt composition and safety-test notes; readonly true.
- Probe 3: scope `Kubebar/Views/SetupView.swift`, `docs/architecture/runtime-invariants.md`, and `CONTEXT.md`; output concise Settings UI and docs wording notes; readonly true.

**Files:**
- Modify: `CONTEXT.md`
- Modify: `docs/architecture/runtime-invariants.md`
- Modify: `KubebarCore/Models/AIDiagnosticAssistantConfig.swift`
- Modify: `KubebarCore/Models/AIDiagnosticAssistantState.swift`
- Modify: `KubebarCore/Models/SetupFlowState.swift`
- Modify: `KubebarCore/Models/MenuRuntimeState.swift` if change detection needs explicit helpers
- Modify: `KubebarCore/Services/AIPodDiagnosticRequester.swift`
- Modify: `KubebarCore/Services/AIEventDiagnosticRequester.swift`
- Modify: `Kubebar/Views/SetupView.swift`
- Modify/Add: `KubebarTests/Models/AppConfigTests.swift`
- Modify/Add: `KubebarTests/Models/SetupFlowStateTests.swift`
- Modify/Add: `KubebarTests/Models/MenuRuntimeStateTests.swift`
- Modify/Add: `KubebarTests/Services/AIPodDiagnosticRequesterTests.swift`
- Modify/Add: `KubebarTests/Services/AIEventDiagnosticRequesterTests.swift`
- Modify/Add: `KubebarTests/Services/AIProviderConnectionTesterTests.swift` if unchanged Test Connection needs an explicit guard
- Add: `changelog.d/ai-diagnostic-prompt-customization.added.md`

**Approach:**
- Extend `AIDiagnosticAssistantConfig` with per-surface prompt override storage plus built-in default/effective prompt helpers.
- Add `SetupFlowState` mutation/reset helpers and Settings bindings so editing a default-backed field creates or updates the override while reset clears it.
- Add compact prompt editor sections under `AI Assistant` Settings for Pod diagnosis and Warning Event diagnosis, each with explanatory copy and `Reset to default`.
- Refactor Pod/Event requester prompt construction to combine fixed system/safety prompt, effective user-editable instructions, and code-owned structured diagnostic context blocks.
- Add/adjust tests for config decode/encode, reset semantics, request-body prompt inclusion, safety boundary preservation, and Test Connection isolation.
- Update docs and changelog, then run focused tests followed by the full quality gate.

**failure_behavior:** If config/default tests fail, stop before wiring UI or requester changes. If requester safety tests fail, do not expose Settings controls. If UI build fails, revert UI additions while preserving coherent Core tests only if the config/requester contract is complete; otherwise revert the whole slice.

**security_considerations:** Prompt customization must not make the system prompt editable, must not broaden diagnostic payloads, must not expose or store API keys outside Keychain, must not send custom prompts via Test Connection, and must not enable automatic command execution.
