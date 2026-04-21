# Phase 05 UAT Checks

Use these visible checks for issue #4 after the local quality gate passes.

- Warning counter remains compact.
- Warning section shows at most 3 summaries.
- Duplicate warnings are grouped.
- Workload row reason is one phrase.
- Detail shows state, reason, affected pod count, 1-3 pod examples, and latest warning when available.
- Malformed or partial section data appears unavailable, not healthy.
- No raw pod/event JSON, full kubectl output, `Open in k9s`, dashboard, or Secrets reads are visible.
