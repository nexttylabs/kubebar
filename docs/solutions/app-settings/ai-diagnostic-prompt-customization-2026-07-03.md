---
module: app-settings
tags:
  - kubebar
  - ai-diagnostics
  - prompt-customization
  - settings
  - safety-boundary
problem_type: customizable-prompt-with-immutable-safety-boundary
reusability: medium
key_files:
  - KubebarCore/Models/AIDiagnosticAssistantConfig.swift
  - KubebarCore/Services/AIPodDiagnosticRequester.swift
  - KubebarCore/Services/AIEventDiagnosticRequester.swift
  - Kubebar/Views/SetupView.swift
  - docs/architecture/runtime-invariants.md
next_reuse_scenarios:
  - Adding user-editable prompt/instruction surfaces to other AI diagnostic flows.
  - Reviewing any feature that lets users customize text sent to an external provider.
  - Extending Settings with a default-backed editor plus reset-to-default semantics.
---

# Customizable AI Prompts Need an Immutable Safety Layer

## Problem

Kubebar's AI Pod and Warning Event diagnoses used hard-coded prompt
instructions. Users asked to customize those prompts based on the built-in
default and reset them to the default. The customization surface had to stay
inside the existing safety boundary: fixed system/safety prompt, bounded
redacted Kubernetes context, no Secrets/kubeconfig/raw transcripts, no
auto-executed commands, and no Health-category effect.

## Solution

Split prompt composition into three code-owned layers and let users edit only
one of them.

- Store per-surface prompt overrides (`podPromptInstructions`,
  `eventPromptInstructions`) as non-secret optional fields on
  `AIDiagnosticAssistantConfig`. They persist in `AppConfig`; API keys stay
  Keychain-only.
- Treat nil, empty, or whitespace-only override text as "use the built-in
  default". `effectivePodPromptInstructions` / `effectiveEventPromptInstructions`
  normalize the stored value before falling back to `defaultPodPromptInstructions`
  / `defaultEventPromptInstructions`.
- The Settings editor binds to the effective prompt so the user starts from the
  default text even when no override is saved. `Reset to default` clears the
  override (`with(podPromptInstructions: nil)`) instead of persisting a copied
  default string, so future built-in default updates still reach users who never
  customized.
- Requesters combine: fixed `systemPrompt` (safety) + effective user-editable
  instructions + code-owned structured diagnostic context block. Users cannot
  remove the safety prefix, the bounded context, or the no-auto-execute
  disclosure.

## Evidence

- `swift test --filter AIPodDiagnosticRequesterTests` passed.
- `swift test --filter AIEventDiagnosticRequesterTests` passed.
- `swift test --filter AppConfigTests` passed.
- `swift test --filter SetupFlowStateTests` passed.
- `swift test --filter MenuRuntimeStateTests` passed.
- `swift test --filter AIProviderConnectionTesterTests` passed.
- `swift build` passed.
- `./scripts/swift-quality-gate.sh local` passed.
- `rtk git diff --check` clean.
- Code-review and UI-review gates recorded pass.

## Reuse Notes

When the next user-editable prompt/instruction surface is added, keep the
override as an optional non-secret field, expose effective text through a
normalized helper, and make reset clear the override rather than copying the
default. Keep the safety prompt and bounded context generation in code so
custom text cannot expand the data boundary or enable auto-remediation.

## Reusability Critique

- Falsifiability: this lesson is too local if Kubebar later replaces prompt
  overrides with a full template language or moves prompt storage to a managed
  profile. The immutable-safety-layer principle still applies, but the field
  shape may not.
- Evidence trail: supported by focused requester/config/state/Test Connection
  tests, full quality gate, diff check, and recorded review gates. Not supported
  by live provider calls or VoiceOver traversal.
- Architecture entropy resistance: this belongs in `docs/solutions/app-settings`
  because it captures the Settings + requester ownership split for user-editable
  prompt text. It should not become a generic rule that every Settings field
  needs a default-backed editor.
