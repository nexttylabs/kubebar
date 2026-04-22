# Phase 07: Add Operator-Facing QA and App Verification - Discussion Log

> Audit trail only. Do not use as input to planning, research, or execution
> agents. Decisions are captured in CONTEXT.md; this log preserves the
> alternatives considered.

**Date:** 2026-04-22
**Phase:** 07-add-operator-facing-qa-and-app-verification
**Areas discussed:** QA evidence form, State coverage, Automation boundary,
Documentation location

---

## QA Evidence Form

| Option | Description | Selected |
| --- | --- | --- |
| UAT table + screenshot paths | Most reviewable evidence format for phase QA. | yes |
| UAT table + written notes | Lightweight but less visual. | no |
| Screenshots first | Visual but easy to lose reasoning. | no |
| the agent decides | Leave evidence format to planning. | no |

**User's choice:** `1A`
**Notes:** The UAT table is the review surface; screenshot paths provide visual
proof.

| Option | Description | Selected |
| --- | --- | --- |
| Main six states | Healthy, Watch, Bad, Stale, first-use, empty-watchlist. | no |
| All issue #7 states plus kubectl failure | Full issue coverage plus failure state. | yes |
| Only stable manual states | Screenshot only what can be reproduced reliably. | no |
| the agent decides | Leave screenshot scope to planning. | no |

**User's choice:** `2B`
**Notes:** kubectl failure is part of the expected state coverage.

| Option | Description | Selected |
| --- | --- | --- |
| Short | State, expected result, actual result, evidence path. | no |
| Medium | Adds why passed or why human confirmation is needed. | no |
| Detailed | Includes steps, observations, limits, and risk. | yes |
| the agent decides | Leave record depth to planning. | no |

**User's choice:** `3C`
**Notes:** Each state evidence row should be detailed enough to audit later.

| Option | Description | Selected |
| --- | --- | --- |
| Fixture or fake runner plus optional manual verification | Proves hard-to-trigger failure states through controlled input. | no |
| Must trigger in real app | Requires live app failure reproduction. | no |
| Automatic tests prove behavior; real app confirms no misleading display | Balanced proof without fragile real-cluster failure setup. | yes |
| the agent decides | Leave failure evidence standard to planning. | no |

**User's choice:** `4C`
**Notes:** kubectl failure behavior must be tested; visible QA confirms the UI
does not mislead.

---

## State Coverage

| Option | Description | Selected |
| --- | --- | --- |
| Fixed fixture or fake runner | Produce a fully healthy snapshot repeatably. | yes |
| Real current cluster state | Depend on whatever cluster is currently healthy. | no |
| Automatic fixture with best-effort real app screenshot | Split proof across test and live app. | no |
| the agent decides | Leave Healthy setup to planning. | no |

**User's choice:** `1A`
**Notes:** Healthy evidence must be repeatable.

| Option | Description | Selected |
| --- | --- | --- |
| Warning events for Watch; not-ready node or bad workload for Bad | Distinguish states by meaningful causes. | yes |
| Only prove labels differ | Minimal label-only proof. | no |
| Each proves both row and top summary | Stronger but narrower than the chosen cause split. | no |
| the agent decides | Leave Watch/Bad distinction to planning. | no |

**User's choice:** `2A`
**Notes:** Watch and Bad must be caused by different operator-facing signals.

| Option | Description | Selected |
| --- | --- | --- |
| first-use is incomplete setup; empty-watchlist is context without targets | Keep the two product states separate. | yes |
| Merge both as one unconfigured state | Simpler but loses trust signal. | no |
| Test first-use only and document empty-watchlist | Less complete than issue #7 needs. | no |
| the agent decides | Leave distinction to planning. | no |

**User's choice:** `3A`
**Notes:** These states protect different runtime guarantees.

| Option | Description | Selected |
| --- | --- | --- |
| Refresh failure with retained old data only | Covers failure retention. | no |
| Old snapshot age-out only | Covers freshness expiration. | no |
| Both refresh failure and old snapshot age-out | Covers both stale causes. | yes |
| the agent decides | Leave stale coverage to planning. | no |

**User's choice:** `4C`
**Notes:** Stale proof must include both failure and age-out.

---

## Automation Boundary

| Option | Description | Selected |
| --- | --- | --- |
| Keep current gate only | Preserve current build/test checks. | no |
| Add QA fixture/checklist generation check | Extend the gate without replacing build/test. | yes |
| Add screenshot generation check | Make screenshots part of the gate. | no |
| the agent decides | Leave gate scope to planning. | no |

**User's choice:** `1B`
**Notes:** The local gate remains the single check but gains QA artifact
generation validation.

| Option | Description | Selected |
| --- | --- | --- |
| Only prove build/test/launch | Minimal smoke test role. | no |
| Record app path, PID, and running state | Treat launch evidence as QA evidence. | yes |
| Automatically open every menu state | Too much for the smoke test. | no |
| the agent decides | Leave smoke test role to planning. | no |

**User's choice:** `2B`
**Notes:** Visible-app smoke evidence should be captured in the QA record.

| Option | Description | Selected |
| --- | --- | --- |
| No, every screenshot must exist | Blocks completion on all visual capture. | no |
| Yes, with human_needed and explicit gaps | Honest completion when automation cannot inspect the menu. | yes |
| Yes, automatic tests are enough with no gap | Hides unresolved visible-app risk. | no |
| the agent decides | Leave completion threshold to planning. | no |

**User's choice:** `3B`
**Notes:** Missing screenshots or blocked menu inspection must be visible in
the final record.

| Option | Description | Selected |
| --- | --- | --- |
| Yes, add a stable QA harness | Stable menu states independent of real cluster. | yes |
| No, use only existing tests and manual steps | Avoids new harness work. | no |
| Only add lightweight fixtures, no full harness | Smaller but may not support screenshots well. | no |
| the agent decides | Leave harness decision to planning. | no |

**User's choice:** `4A`
**Notes:** A dedicated harness is required so QA states are repeatable.

---

## Documentation Location

| Option | Description | Selected |
| --- | --- | --- |
| .planning phase UAT only | Keep evidence local to this phase. | no |
| docs/qa/operator-verification.md only | Long-term doc only. | no |
| Both phase UAT and long-term docs | Phase evidence plus durable operator guide. | yes |
| the agent decides | Leave doc location to planning. | no |

**User's choice:** `1C`
**Notes:** Phase evidence and durable QA instructions have different jobs.

| Option | Description | Selected |
| --- | --- | --- |
| .planning phase evidence directory | Keep screenshots beside phase docs. | no |
| docs/assets/qa/ | Shared committed QA screenshot location. | yes |
| Do not commit screenshots, only record local paths | Avoids assets but weakens review evidence. | no |
| the agent decides | Leave screenshot location to planning. | no |

**User's choice:** `2B`
**Notes:** Screenshots should live in `docs/assets/qa/`.

| Option | Description | Selected |
| --- | --- | --- |
| Add a small README pointer | README mentions QA or quality gate. | no |
| Do not update README | Keep README product-focused. | no |
| Only update docs/architecture | Use existing docs entry points. | yes |
| the agent decides | Leave README decision to planning. | no |

**User's choice:** `3C`
**Notes:** README should not be expanded for this phase.

| Option | Description | Selected |
| --- | --- | --- |
| List pending-human-verification explicitly | Keep incomplete manual checks honest. | yes |
| Mark passed with caveat notes | Can misrepresent status. | no |
| Omit unverified items | Hides gaps. | no |
| the agent decides | Leave pending wording to planning. | no |

**User's choice:** `4A`
**Notes:** Unverified items must remain visible as pending.

---

## the agent's Discretion

- Exact harness shape, file names, screenshot names, and command names are open
  to planning if the locked evidence and state coverage decisions are
  preserved.

## Deferred Ideas

- Distribution, signing, notarization, and install packaging remain out of
  scope for issue #7.
- Deep debugging handoff such as `Open in k9s` remains out of scope for issue
  #7.
