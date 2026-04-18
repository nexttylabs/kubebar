---
name: review-checklist
version: 0.1.0
description: Use when deciding whether a change is ready to merge and a concise cross-language checklist is more useful than a full narrative review.
activation:
  patterns:
    - "review.*checklist"
    - "ready to merge"
    - "pre-merge check"
  keywords:
    - review
    - checklist
    - merge
    - pre-merge
  max_context_tokens: 1500
---

# Pre-Merge Review Checklist

Run through each section before approving a merge. Every item applies regardless of language or framework.

## Security & Data Safety

- [ ] **Parameter redaction before logging** — Sensitive fields (tokens, passwords, PII) are stripped or masked before they reach any log output.
- [ ] **URL validation** — User-supplied URLs are validated against an allowlist of schemes and hosts. Reject `file://`, `ftp://`, and internal network addresses.
- [ ] **Destructive operations require approval** — Any action that deletes, overwrites, or irreversibly mutates data must be gated behind an explicit confirmation step.
- [ ] **Untrusted data handling** — External input is sanitized, length-limited, and type-checked before use. Never interpolate raw input into queries, commands, or templates.
- [ ] **No secrets in error messages** — Stack traces, error responses, and debug output must not contain credentials, internal paths, or infrastructure details.

## String Safety

- [ ] **No byte-index slicing on external strings** — Slicing by byte offset on user-supplied or locale-dependent text can split multi-byte characters. Use grapheme-aware or codepoint-aware operations.
- [ ] **Case-insensitive comparisons where needed** — Identifiers, emails, header names, and other case-insensitive values must be compared using a case-folding function, not raw equality.

## Tests

- [ ] **Use temporary directories** — Tests that write to the filesystem must use the platform's temp-directory facility, not hardcoded paths.
- [ ] **No global state mutation** — Tests must not modify global or shared mutable state. Each test should set up and tear down its own fixtures.
- [ ] **No real network requests** — Tests must stub or mock all HTTP, DNS, and socket calls. If an integration test intentionally hits the network, it must be clearly tagged and skippable.
- [ ] **Test names match behavior** — Each test name describes the scenario and expected outcome, not the implementation detail being exercised.

## Documentation

- [ ] **Comments match actual behavior** — Stale comments that contradict the code are worse than no comments. Verify or remove any comment touched by the diff.
- [ ] **Specs updated if behavior changed** — If the change alters observable behavior, the corresponding specification, README, or API docs must be updated in the same changeset.
- [ ] **Error messages are clear** — User-facing and developer-facing error messages state what went wrong and, where possible, suggest a corrective action.

## Error Handling

- [ ] **Errors not swallowed silently** — Every catch/rescue/except block must either handle the error meaningfully, re-raise it, or log it at an appropriate level. Empty handlers are not acceptable.
- [ ] **Error types carry enough context** — Custom error types include the failing input, operation name, or upstream cause so that a handler further up the stack can make an informed decision.
- [ ] **Consistent error handling patterns** — The changeset follows the same error-propagation style used in the surrounding codebase (e.g., result types, exceptions, error codes). Do not mix conventions within a module.
