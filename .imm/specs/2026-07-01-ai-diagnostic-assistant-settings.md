# AI Diagnostic Assistant Settings

## Summary

Kubebar will add an app-wide AI Diagnostic Assistant settings slice. Users can choose an AI provider, enter a model, store the provider API key in macOS Keychain, and manually run a safe Test Connection. The current executable slice does not send Kubernetes data for diagnosis; it preserves the confirmed privacy boundary that any later diagnostic payload is limited to user-approved warning text.

## Output Language

Spec and Plan prose are written in English. Code identifiers, schema fields, CLI commands, file paths, provider names, and Immune-Brain fields remain literal.

## Requirements

- R1: Add an `AI Diagnostic Assistant` section to the fixed `App Settings tab`.
- R2: Support provider choices `OpenAI`, `Anthropic`, `Google Gemini`, and `OpenAI-compatible`.
- R3: Remove the originally proposed `Ollama` option from the first version.
- R4: Allow a user-defined `Model ID` for the selected provider.
- R5: For `OpenAI-compatible`, allow only `Bearer` API key authentication, `Base URL`, and `Model ID`; custom headers are out of scope.
- R6: Persist only non-secret AI Provider configuration in local app config.
- R7: Store AI Provider API keys in macOS Keychain, never in `AppConfig` or `config.json`.
- R8: Provide a manually triggered `Test Connection` action for the saved or edited provider configuration.
- R9: Test Connection failure feedback must be safe: no raw API key, `Authorization` header, complete response body, raw request, or token-like text may be shown.
- R10: External AI calls must go through injectable boundaries. SwiftUI views must not construct provider requests or read secrets directly.
- R11: Test Connection must not send Kubernetes warnings, Pod logs, kubeconfig content, Secrets, raw `kubectl` output, or cluster JSON.
- R12: Any future AI diagnostic request in this feature area must be manually triggered and limited to warning summary text.
- R13: AI results and provider state must not affect `HealthEvaluator`, `MenuDisplayModel` health categorization, or the menu bar icon category.

## Non-goals

- No Ollama provider in this version.
- No automatic or background AI diagnosis.
- No Pod log submission.
- No Kubernetes Secret reads or transmission.
- No full `kubectl` transcript or cluster JSON transmission.
- No chat history, account system, OAuth, cloud sync, prompt-template system, custom headers, or provider-specific advanced tuning.

## Data and Security Boundaries

`AI Provider configuration` is app-wide and may be saved with other local Settings metadata. `AI Provider API key` is secret material and belongs only in the Keychain credential boundary. Test Connection uses a minimal provider request and must sanitize transport, validation, and provider-error output before any text reaches runtime state or UI.

The current slice only proves that provider configuration and credentials are usable. It does not implement warning explanation. The warning-text diagnostic boundary is preserved for a later plan so the future diagnostic slice cannot expand silently to Pod logs, Secrets, raw command output, or cluster JSON.

## Success Criteria

- Existing configs decode with default AI Provider configuration and no credential requirement.
- Saving Settings round-trips provider/model/base URL metadata without serializing an API key.
- Keychain operations are covered through an injectable credential-store protocol and fakes.
- Test Connection request construction is covered for all four provider choices and validates the `OpenAI-compatible` Bearer/Base URL/Model ID contract.
- Safe failure tests prove secrets and token-like values are redacted.
- The App Settings UI exposes provider, model, OpenAI-compatible base URL, API key entry, and a manual Test Connection action.
- Runtime docs preserve the rule that AI does not affect Health category and diagnostic input remains manually approved warning text only.
