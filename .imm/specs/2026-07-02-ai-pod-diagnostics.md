# AI Pod Diagnostics

## Summary

Kubebar will add a manually triggered `AI Diagnose this Pod` action to the Pod Micro-Logs Drawer. When the user clicks the action, Kubebar rereads the selected Pod's last 50 log lines, combines them with the current display-model Pod status and the latest 3 related warning summaries, sends that minimal troubleshooting context to the configured AI Provider, and renders a structured Markdown report below the logs.

This changes the earlier diagnostic input boundary from warning-summary-only to user-approved Pod diagnostic context that may include redacted log text. It remains display/help behavior only and never affects `HealthEvaluator`, `MenuDisplayModel` health categorization, or the menu bar icon category.

## Output Language

Spec and Plan prose are English. Code identifiers, schema fields, CLI commands, file paths, provider names, API names, enum cases, Markdown headings, and Immune-Brain fields remain literal.

## Requirements

- R1: Add a contextual `sparkles` / `AI Diagnose this Pod` action to the Pod Micro-Logs Drawer toolbar, near search/copy controls.
- R2: Do not add the primary AI diagnosis action to the menu footer because footer actions are app-level utilities and the diagnosis target must be explicit.
- R3: Diagnosis is always manually triggered by the user; no automatic, scheduled, background, or refresh-triggered AI diagnosis.
- R4: The diagnostic request rereads Pod logs with `kubectl logs --tail=50` for the selected Pod, instead of reusing the live drawer buffer.
- R5: The diagnostic context includes the selected Pod's current display-ready status/reason, the latest 3 related warning summaries when available, and the last 50 log lines.
- R6: Before or while triggering diagnosis, the UI clearly communicates that Pod status, warning summaries, and last 50 log lines will be sent to the configured AI Provider.
- R7: Log text sent to the provider must be bounded and pass through basic secret redaction for obvious tokens, authorization headers, passwords, and API-key-like fields.
- R8: AI Provider API keys remain Keychain-only and must never appear in AppConfig, command output, visible errors, or diagnostic reports.
- R9: AI calls go through injectable service boundaries; SwiftUI views do not construct provider requests, read credentials, or invoke `kubectl` directly.
- R10: AI results render as human-readable Markdown with `🔍 Possible causes` and `🛠️ Actionable fixes` sections.
- R11: Suggested `kubectl` commands are copyable text only; Kubebar must not automatically execute AI-suggested commands or mutate Kubernetes resources.
- R12: Failure states are safe and actionable for unconfigured provider, missing API key/model/base URL, log read failure, event unavailability, provider timeout/network failure, provider HTTP failure, empty logs, and stale data.
- R13: AI diagnosis must not query Kubernetes Secrets, send kubeconfig content, send full raw `kubectl` transcripts, send raw cluster JSON, persist history, or cloud-sync reports.
- R14: AI diagnosis must not affect `HealthEvaluator`, `MenuDisplayModel` health categorization, watchlist ordering, alerts, or menu bar icon state.

## Non-goals

- No global cluster AI diagnosis from the footer.
- No primary Warning Events AI diagnosis in the MVP.
- No auto-executed remediation commands.
- No Secret reads, kubeconfig transmission, raw cluster JSON, full kubectl transcript submission, or provider response raw-body display.
- No chat history, conversation memory, cloud sync, prompt template editor, provider advanced tuning, or custom headers.
- No previous-container logs or multi-container selection in this slice.

## Data and Security Boundaries

The Pod AI diagnostic payload is manually triggered and target-scoped. It may include redacted last-50-line Pod logs only after the user acts from the Pod Micro-Logs Drawer, where the exact Pod target is visible. The request uses the app-owned context and effective kubeconfig rules used by other `kubectl` reads. The app reads logs through an injectable command boundary and sends provider requests through the existing AI credential/HTTP boundary pattern.

Visible failures must be sanitized: no API key, Bearer token, Authorization header, raw HTTP body, raw request, raw stderr transcript, kubeconfig path content beyond existing safe display strings, or token-like values. The report is transient UI state; it is not persisted and is not an input to health evaluation.

## Success Criteria

- A Bad Pod row can open the existing Pod Micro-Logs Drawer and run `AI Diagnose this Pod` from the drawer toolbar.
- The finite diagnostic log read uses `kubectl --context <context> logs --tail=50 -n <namespace> <pod>` with the app-owned context and configured kubeconfig environment.
- Provider request tests prove the body contains the structured diagnostic context, asks for `🔍 Possible causes` and `🛠️ Actionable fixes`, and avoids raw kubeconfig, Secrets, raw cluster JSON, and full command transcripts.
- Redaction tests prove obvious secrets in log text and provider/transport errors are not surfaced or sent unredacted.
- UI state tests or focused model tests prove diagnosis has loading, success, retryable failure, and unavailable-configuration states.
- Documentation updates reflect the new user-approved Pod log submission boundary while preserving display-only health behavior.
- The Swift quality gate passes.
