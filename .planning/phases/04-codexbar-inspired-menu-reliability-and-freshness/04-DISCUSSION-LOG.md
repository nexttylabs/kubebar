# Phase 04: CodexBar-Inspired Menu Reliability and Freshness - Discussion Log

> Audit trail only. Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves alternatives considered.

**Date:** 2026-04-21
**Phase:** 04-codexbar-inspired-menu-reliability-and-freshness
**Source issue:** https://github.com/nexttylabs/kubebar/issues/5
**Areas discussed:** stale threshold, failed refresh handling, failure reasons, refresh concurrency, menu refresh controls

---

## Stale Threshold

| Option | Description | Selected |
| --- | --- | --- |
| Over 2x refresh cadence | Tie freshness to the saved interval; default 1 minute cadence becomes stale after 2 minutes. | yes |
| Fixed 5 minutes | Quieter, but lets short-cadence data look fresh too long. | |
| Severity-specific threshold | More precise, but adds more rules. | |

**User's choice:** Over 2x refresh cadence.
**Notes:** Freshness should be clear and tied to the saved cadence rather than hidden configuration.

---

## Failed Refresh Handling

| Option | Description | Selected |
| --- | --- | --- |
| Quiet stale retention | Keep last successful data, mark it stale, update reason and last successful update time. | yes |
| Escalate after repeated failures | Stronger reminder, but requires extra UI and thresholds. | |
| Clear old data immediately | Conservative, but less useful and conflicts with stale-retention rules. | |

**User's choice:** Quiet stale retention.
**Notes:** Consecutive failures should not erase the last useful snapshot or create noisy prompts.

---

## Failure Reasons

| Option | Description | Selected |
| --- | --- | --- |
| Distinct short reasons in one Stale state | Timeout, command failure, malformed JSON, and no prior data are distinct but use the same stale UI. | yes |
| Multiple visual states | More detailed, but breaks the four-state icon rule. | |
| Generic Refresh failed | Simple, but not actionable enough for issue #5. | |

**User's choice:** Distinct short reasons in one Stale state.
**Notes:** Keep `OK`, `Watch`, `Bad`, and `Stale` as the only top-level states.

---

## Refresh Concurrency

| Option | Description | Selected |
| --- | --- | --- |
| Single in-flight refresh | Only one refresh runs at a time; disable `Retry now` while refreshing. | yes |
| Concurrent refreshes, last-started wins | Flexible, but harder to implement and test. | |
| Concurrent refreshes, first-finished wins | Simple, but can let older work overwrite newer intent. | |

**User's choice:** Single in-flight refresh.
**Notes:** Manual retry and automatic refresh must not start overlapping `kubectl` reads.

---

## Menu Refresh Controls

| Option | Description | Selected |
| --- | --- | --- |
| Cadence, last updated, failure reason, Retry now | Enough to judge trust without expanding the menu. | yes |
| Add progress and next-refresh countdown | More transparent, but makes the menu busier. | |
| Only Retry now and stale banner | Minimal, but hides cadence and freshness context. | |

**User's choice:** Cadence, last updated, failure reason, Retry now.
**Notes:** The menu should remain compact and glanceable.

---

## the agent's Discretion

- Exact wording for short failure reasons.
- Exact internal model names for freshness and in-flight refresh state.
- Exact button disabled styling while refresh is running.

## Deferred Ideas

- Persistent next-refresh countdown.
- Richer refresh progress panel.
- New top-level visual states beyond `OK`, `Watch`, `Bad`, and `Stale`.
