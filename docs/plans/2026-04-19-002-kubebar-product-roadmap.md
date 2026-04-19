---
title: chore: Kubebar product roadmap and GitHub issue plan
type: chore
status: active
date: 2026-04-19
origin:
  - docs/brainstorms/2026-04-19-kubebar-watchlist-first-requirements.md
  - docs/plans/2026-04-19-001-feat-kubebar-watchlist-menu-plan.md
  - docs/architecture/system-overview.md
  - docs/architecture/runtime-invariants.md
---

# Kubebar Product Roadmap and GitHub Issue Plan

## Source Reading

The docs define Kubebar as a native macOS menu bar utility for one daily
Kubernetes operator. The product goal is fast trust: icon state, saved context,
compact node/pod/event counts, a small personal watchlist, and stale handling
that never makes old data look healthy.

The first implementation plan has already produced the main app shape:
`MenuBarExtra`, `KubebarCore`, `kubectl` reads, saved config, display models,
refresh coordination, and tests. The remaining plan should therefore focus on
operator readiness rather than recreating the foundation.

The `docs/superpowers/` Swift iOS support files are template-era context. They
are not part of the Kubebar product direction and should be archived, removed,
or clearly separated from current product docs.

## Product Priorities

1. Make setup real enough for daily use.
2. Make warning and workload reasons actionable at a glance.
3. Make refresh and stale states trustworthy.
4. Make the menu feel native, readable, and keyboard-friendly.
5. Add enough verification to trust the app before packaging.
6. Package the app for local installation when the daily-use loop is stable.

## Planned GitHub Issues

| Order | Issue | Purpose | Source |
| --- | --- | --- | --- |
| 1 | [#2 Clean up product docs and stale template notes](https://github.com/nexttylabs/kubebar/issues/2) | Keep the repo understandable as Kubebar, not a leftover template | Architecture notes, README, `docs/superpowers/` |
| 2 | [#3 Complete first-use setup and watchlist editing](https://github.com/nexttylabs/kubebar/issues/3) | Let the user choose context and watch targets without manual config | R14-R17 |
| 3 | [#4 Expand kubectl data into actionable warning and workload reasons](https://github.com/nexttylabs/kubebar/issues/4) | Make rows explain what is wrong, not just that something is wrong | R3, R8, R9, R12 |
| 4 | [#5 Add refresh cadence, timeout, and freshness controls](https://github.com/nexttylabs/kubebar/issues/5) | Make current/stale/failure states predictable and visible | R10-R12 |
| 5 | [#6 Polish menu bar icon states and keyboard navigation](https://github.com/nexttylabs/kubebar/issues/6) | Make the app readable from the menu bar and usable without a mouse | R1, R13, R18-R21 |
| 6 | [#7 Add operator-facing QA and app verification](https://github.com/nexttylabs/kubebar/issues/7) | Verify the daily menu states against real app behavior | Success criteria |
| 7 | [#8 Prepare local macOS distribution](https://github.com/nexttylabs/kubebar/issues/8) | Make the app installable after the core loop is stable | Deferred distribution work |
| 8 | [#9 Explore optional deeper-debugging handoff](https://github.com/nexttylabs/kubebar/issues/9) | Keep `Open in k9s` or watch-stream work as explicit backlog, not V1 scope creep | Deferred future work |

## Sequencing

Issues 1-2 should come first because setup and docs determine whether a new
user can try the app. Issues 3-5 make the daily status signal trustworthy and
comfortable. Issue 6 is the readiness gate before any install/distribution
work. Issue 7 follows only after the menu loop is stable. Issue 8 remains
backlog unless daily use shows that deeper handoff is needed.

## Completion Bar

- A user can open the app, pick a saved context, choose watch targets, and see
  a trustworthy menu state without editing files.
- Warning events and unhealthy watchlist rows explain the reason briefly.
- Failed refreshes are visibly stale and still useful.
- The menu bar icon differentiates `OK`, `Watch`, `Bad`, and `Stale`.
- Quality checks include Xcode build, Xcode tests, Swift build, and Swift tests.
- Product docs describe Kubebar clearly without template-era confusion.
