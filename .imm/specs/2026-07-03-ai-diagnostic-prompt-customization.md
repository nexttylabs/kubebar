# AI Diagnostic Prompt Customization

## Summary

Kubebar will let users customize the prompt instructions used by manual AI Pod diagnosis and manual AI Warning Event diagnosis. Users can start from Kubebar's default prompt text, edit per diagnostic surface, save the custom instructions in local non-secret app config, and reset either surface back to the built-in default. Kubebar keeps immutable safety instructions and structured diagnostic context generation in code so prompt customization cannot expand the submitted Kubernetes data boundary or enable automatic remediation.

## Output Language

Spec and Plan prose are written in English. Code identifiers, schema fields, CLI commands, file paths, provider names, API names, enum cases, Markdown headings, and Immune-Brain fields remain literal.

## Requirements

- R1: Add per-surface prompt customization for manual `AI Pod diagnosis` and manual `AI Event diagnosis`.
- R2: The `AI Assistant` Settings page must show editable text initialized from the effective default prompt instructions so users can modify the default rather than starting from a blank field.
- R3: The Settings page must provide `Reset to default` behavior for each prompt surface.
- R4: Reset must remove the custom override and return to the built-in default rather than persisting a copied default string.
- R5: Existing `AppConfig` files without prompt fields must decode successfully and use the built-in default prompts.
- R6: Prompt overrides are non-secret local settings and may be persisted in `AppConfig`; API keys remain Keychain-only.
- R7: Manual Pod diagnosis must use the configured Pod prompt instructions while preserving fixed safety instructions, bounded/redacted last-50 log context, warning cap, app-owned context, and no automatic command execution.
- R8: Manual Event diagnosis must use the configured Event prompt instructions while preserving fixed safety instructions, latest-5 matching Warning Event context, event-only payload, app-owned context, and no automatic command execution.
- R9: Users must not be able to override the immutable safety/system prompt that tells the provider to use only supplied context and not claim command execution.
- R10: Blank or whitespace-only custom prompt text must fall back safely to the built-in default.
- R11: Test Connection remains a provider ping only and must not send custom prompts or Kubernetes data.
- R12: AI prompt customization and AI results must not affect `HealthEvaluator`, `MenuDisplayModel` health categorization, Health State Shift Alerts, watchlist ordering, or the menu bar icon category.

## Non-goals

- No global cluster diagnosis prompt.
- No Events tab diagnosis entry.
- No chat history, diagnosis history, cloud sync, or remote prompt sharing.
- No custom provider headers, model parameter tuning, prompt variables UI, or full template language.
- No user-editable safety/system prompt.
- No automatic/background diagnosis and no automatic execution of suggested `kubectl` commands.
- No expansion of submitted diagnostic data beyond the existing Pod and Event diagnosis boundaries.

## Data and Security Boundaries

Prompt customization changes only the natural-language instructions used in manual AI diagnosis requests. The diagnostic data included in requests remains code-owned and bounded by existing runtime invariants: Pod diagnosis may include the selected Pod's display-ready status, up to 3 warning summaries, and freshly read/redacted `kubectl logs --tail=50`; Event diagnosis may include only the latest 5 fresh exact-key matching Warning Events. Secrets, kubeconfig content, raw command transcripts, raw cluster JSON, and provider raw response bodies remain excluded.

Prompt overrides are not credentials. They may be serialized inside `AppConfig` with other non-secret AI Provider configuration. API keys remain in macOS Keychain only.

## Success Criteria

- Existing configs decode with no prompt customization and produce the same effective default prompt behavior.
- Saving Settings round-trips prompt overrides without writing API keys to `AppConfig`.
- Each prompt surface has a visible editor and a `Reset to default` action in `AI Assistant` Settings.
- Reset produces default effective prompt text and removes the custom override from persisted config.
- Pod requester tests prove custom Pod prompt instructions appear in the provider request while the fixed safety prompt and bounded/redacted context remain present.
- Event requester tests prove custom Event prompt instructions appear in the provider request while the fixed safety prompt and latest-5 event context remain present.
- Blank custom prompt text falls back to built-in defaults.
- Test Connection request behavior remains unchanged and sends no custom prompts or Kubernetes data.
- Full Swift quality gate passes.
