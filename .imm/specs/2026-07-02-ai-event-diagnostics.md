# AI Event Diagnostics

## Summary

Kubebar will add a manually triggered AI diagnosis action to `Overview` `Recent Warnings`. When the user clicks a warning row action, Kubebar rereads Warning Events through `kubectl`, filters the fresh result by the selected warning group's `namespace`, `objectKind`, `objectName`, and `reason`, sends the latest 5 matching Warning Events to the configured AI Provider, and renders a transient diagnosis.

This is an event-only diagnostic path. It does not read Pod logs, does not diagnose from the Events tab, and does not execute any AI-suggested commands. AI output remains display/help behavior only and never affects `HealthEvaluator`, `MenuDisplayModel` health categorization, Health State Shift Alerts, watchlist ordering, or the menu bar icon category.

## Output Language

Spec and Plan prose are English. Code identifiers, schema fields, CLI commands, file paths, provider names, API names, enum cases, Markdown headings, and Immune-Brain fields remain literal.

## Requirements

- R1: Add a manual AI diagnosis entry only to `Overview` `Recent Warnings` rows.
- R2: Do not add the diagnosis entry to the Events tab in this slice.
- R3: Match the selected warning group by exact `namespace`, `objectKind`, `objectName`, and `reason`; do not use substring matching.
- R4: Reread Warning Events with `kubectl` at diagnosis time instead of reusing the current snapshot rows.
- R5: The fresh `kubectl` read must use Kubebar's app-owned selected context and effective kubeconfig rules.
- R6: Send only the latest 5 matching Warning Events to the configured AI Provider.
- R7: The event diagnostic payload may include structured event fields such as context, namespace, object kind, object name, reason, message/note, observed timestamp, and count. It must not include Pod logs, kubeconfig content, Secrets, full raw cluster JSON, or raw command transcripts.
- R8: Event message text sent to the provider must pass through basic secret redaction for obvious tokens, authorization headers, passwords, and API-key-like fields.
- R9: AI Provider API keys remain Keychain-only and must never appear in AppConfig, command output, visible errors, or diagnostic reports.
- R10: AI calls and `kubectl` reads go through injectable service boundaries; SwiftUI views do not construct provider requests, read credentials, or invoke `kubectl` directly.
- R11: AI results render as human-readable Markdown with concise possible causes and actionable fixes.
- R12: Suggested `kubectl` commands are copyable text only; Kubebar must not automatically execute AI-suggested commands or mutate Kubernetes resources.
- R13: Failure states are safe and actionable for unconfigured provider, missing API key/model/base URL, event read failure, no matching fresh events, provider timeout/network failure, provider HTTP failure, and stale display data.
- R14: AI event diagnosis must not affect `HealthEvaluator`, `MenuDisplayModel` health categorization, watchlist ordering, alerts, or menu bar icon state.

## Non-goals

- No Events tab diagnosis entry in this slice.
- No Pod log reads for event diagnosis.
- No global cluster AI diagnosis from the footer.
- No automatic/background AI diagnosis on refresh or alert creation.
- No auto-executed remediation commands.
- No Secret reads, kubeconfig transmission, raw cluster JSON, full kubectl transcript submission, or provider response raw-body display.
- No persisted diagnosis history, chat UX, report archive, cloud sync, prompt template editor, provider advanced tuning, or custom headers.

## Data and Security Boundaries

The AI event diagnostic payload is manually triggered and warning-group-scoped. It is limited to the latest 5 fresh Warning Events matching the selected `Overview` `Recent Warnings` row's exact target key. The request uses the app-owned context and effective kubeconfig rules used by other `kubectl` reads.

Visible failures must be sanitized: no API key, Bearer token, Authorization header, raw HTTP body, raw request, raw stderr transcript, kubeconfig content, or token-like values. The report is transient UI state; it is not persisted and is not an input to health evaluation.

## Success Criteria

- `Overview` `Recent Warnings` rows expose a manual AI diagnosis entry, while Events tab rows do not.
- Clicking the action performs a fresh `kubectl --context <context> get events ... -o json` style read through an injectable boundary with the configured kubeconfig environment.
- Matching uses exact `namespace`, `objectKind`, `objectName`, and `reason`, sorts by observed timestamp, and caps provider input at the latest 5 matching Warning Events.
- Provider request tests prove the body contains structured event context and does not contain Pod logs, kubeconfig content, raw cluster JSON, or raw command transcripts.
- Redaction tests prove obvious secrets in event messages and visible provider/transport errors are not surfaced or sent unredacted.
- UI/model behavior supports loading, success, retryable failure, no-match, and unavailable-configuration states without expanding the Events tab scope.
- Documentation updates preserve display-only health behavior.
- The Swift quality gate passes.
