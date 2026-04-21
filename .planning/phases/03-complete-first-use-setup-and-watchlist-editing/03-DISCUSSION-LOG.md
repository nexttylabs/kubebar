# Phase 03: Complete first-use setup and watchlist editing - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution
> agents. Decisions are captured in `03-CONTEXT.md`; this log preserves the
> alternatives considered.

**Date:** 2026-04-20
**Phase:** 03-complete-first-use-setup-and-watchlist-editing
**Source issue:** https://github.com/nexttylabs/kubebar/issues/3
**Areas discussed:** Watchlist candidate discovery

---

## Watchlist Candidate Discovery

### Question 1: Which candidate types should the setup show?

| Option | Description | Selected |
| --- | --- | --- |
| Namespaces + common workloads | Supports broad namespace monitoring and focused service monitoring. | Yes |
| Namespaces only | Simplest and quietest, but less useful for service-focused watching. |  |
| Workloads only | More precise, but can make first setup too long and dense. |  |

**User's choice:** Namespaces + common workloads.

### Question 2: Which common workload kinds should be included?

| Option | Description | Selected |
| --- | --- | --- |
| Deployment / StatefulSet / DaemonSet | Covers long-running services with a restrained list. |  |
| Deployment / StatefulSet / DaemonSet / Job / CronJob | Covers services plus scheduled/batch workloads. | Yes |
| All discoverable workloads | Most complete, but likely too noisy for first setup. |  |

**User's choice:** Include Job and CronJob initially, then refine Job behavior
in the next question.

### Question 3: How should Job noise be handled?

| Option | Description | Selected |
| --- | --- | --- |
| Show CronJob, not historical Job | Keeps scheduled workloads while avoiding completed Job clutter. | Yes |
| Show CronJob plus running or failed Job | More current but more complex. |  |
| Show all Job objects | Complete but too noisy. |  |

**User's choice:** Show CronJob, not historical Job.

### Question 4: How should candidates be arranged?

| Option | Description | Selected |
| --- | --- | --- |
| Group by namespace, with kind and name inside each group | Easier to find services and distinguish same-named workloads. | Yes |
| Flat list with namespace/type/name | More search-like but denser. |  |
| Choose namespace first, then show workloads | Quieter but adds a step. |  |

**User's choice:** Group by namespace.

### Question 5: How should a long candidate list stay quiet?

| Option | Description | Selected |
| --- | --- | --- |
| Namespace groups default collapsed | Keeps large clusters calm and scannable. | Yes |
| Everything expanded | Direct but too long on larger clusters. |  |
| Show first namespaces, hide the rest behind more | Shorter but may imply missing data. |  |

**User's choice:** Namespace groups default collapsed.

### Question 6: How should loading be shown?

| Option | Description | Selected |
| --- | --- | --- |
| Keep context visible; show loading in watchlist area | Makes the active context clear while candidates load. | Yes |
| Whole setup page loading | Simple but freezes too much of the flow. |  |
| No loading state | Quiet but confusing when `kubectl` is slow. |  |

**User's choice:** Keep context visible; show loading in watchlist area.

### Question 7: How should discovery failure behave?

| Option | Description | Selected |
| --- | --- | --- |
| Show failure reason + retry; preserve selected watchlist | Clear recovery without losing partial setup work. | Yes |
| Clear candidates and show failure only | Simple but risks looking like selections were lost. |  |
| Return to context selection | Too heavy for one command failure. |  |

**User's choice:** Show failure reason + retry; preserve selected watchlist.

### Question 8: When should candidates reload?

| Option | Description | Selected |
| --- | --- | --- |
| Automatically after context selection/change | Most natural for first setup. | Yes |
| Only after clicking Load targets | More controlled, but adds setup friction. |  |
| Only after Finish setup | Least noisy, but prevents review before saving. |  |

**User's choice:** Automatically after context selection/change.

---

## the agent's Discretion

- Context switching cleanup rules beyond automatic reload were not selected.
- Empty-state wording and edit save timing were not selected.
- Planner may choose conservative defaults that preserve app-owned context and
  never show targets from the wrong context.

## Deferred Ideas

- Issue #4 should handle richer workload warning reasons and warning event
  summaries.
- Issue #5 should handle refresh cadence, timeout behavior, and stale controls.
