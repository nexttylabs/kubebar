# Kubebar Handoff

**Last updated**: 2026-07-03T15:15:00Z

## Current State

- Plan: `docs/plans/2026-07-03-001-feat-ai-diagnostic-prompt-customization-plan.md`
- Summary: `AI Assistant` Settings now supports separate custom prompt instructions for Pod diagnosis and Warning Event diagnosis. Each editor starts from the built-in default and can reset by clearing the custom override. Requesters keep fixed safety/system prompts and code-owned bounded diagnostic context.
- Status: complete; Step U1 passed QA.
- Completed steps:
  - U1 (closed): `AI Assistant` Settings supports safe prompt customization/reset for Pod/Event diagnosis.
- Active step: none.
- Known blockers: none.

## Verification

- `swift test --filter AIPodDiagnosticRequesterTests && swift test --filter AIEventDiagnosticRequesterTests && swift test --filter AppConfigTests && swift test --filter SetupFlowStateTests && swift test --filter MenuRuntimeStateTests && swift test --filter AIProviderConnectionTesterTests` passed.
- `swift build` passed.
- `./scripts/swift-quality-gate.sh local` passed.
- `rtk git diff --check` clean.

## Notes

- Prompt overrides are non-secret local `AppConfig` fields; API keys remain Keychain-only.
- Reset to default clears the override instead of persisting a copied default prompt.
- Custom instructions do not replace the fixed safety prompt and do not expand submitted Pod/Event diagnostic data.
- Test Connection remains a provider ping and sends no custom prompts or Kubernetes data.

## Compaction Handoff

- Active plan: `docs/plans/2026-07-03-001-feat-ai-diagnostic-prompt-customization-plan.md`
- Active Step ID plus Result: none active; U1 passed — `AI Assistant` Settings supports safe prompt customization/reset for Pod/Event diagnosis.
- Priority files for reload:
  - `KubebarCore/Models/AIDiagnosticAssistantConfig.swift`
  - `Kubebar/Views/SetupView.swift`
  - `KubebarCore/Services/AIPodDiagnosticRequester.swift`
  - `KubebarCore/Services/AIEventDiagnosticRequester.swift`
  - `docs/architecture/runtime-invariants.md`
- Uncommitted work summary: AI diagnostic prompt customization implementation, docs/spec/plan/changelog, runtime state, handoff update, and focused tests are uncommitted.
- Session decisions: Pod and Warning Event prompts are separate; reset clears overrides; fixed safety/system prompt and bounded diagnostic context remain code-owned.
- Next boundary skill: none required unless user asks for follow-up; otherwise ready for review/commit.
