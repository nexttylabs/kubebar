# Phase 04 Research: CodexBar Design Lessons for Kubebar

**Date:** 2026-04-21
**Status:** Complete

## Sources

- `https://github.com/steipete/CodexBar`
- `/tmp/codexbar-study/README.md`
- `/tmp/codexbar-study/docs/architecture.md`
- `/tmp/codexbar-study/docs/ui.md`
- `/tmp/codexbar-study/docs/refresh-loop.md`
- `/tmp/codexbar-study/docs/provider.md`
- `/tmp/codexbar-study/Sources/CodexBar/StatusItemController.swift`
- `/tmp/codexbar-study/Sources/CodexBar/MenuDescriptor.swift`
- `/tmp/codexbar-study/Sources/CodexBar/MenuContent.swift`
- `/tmp/codexbar-study/Sources/CodexBar/UsageStore.swift`
- `/tmp/codexbar-study/Sources/CodexBar/ProviderRegistry.swift`

## CodexBar Design Logic

CodexBar treats the menu bar as a reliable instrument instead of a small
dashboard. The app has a compact status item, a menu that explains the current
signal, a refresh loop, model seams around menu content, and scripts/docs that
make local verification repeatable.

Patterns worth adapting:

- **Run verification:** CodexBar has a script-oriented local app loop. This is
  valuable because menu bar UI bugs often require launching the real app.
- **Menu model seam:** CodexBar builds menu content through descriptor-like
  structures instead of scattering state decisions directly through views.
- **Refresh loop ownership:** Refresh timing, stale/error state, and visible
  status are treated as product behavior, not incidental background work.
- **Icon as first signal:** The status item carries compressed state, with the
  menu providing the explanation.
- **Docs as guardrails:** Architecture docs record what the menu bar app reads,
  owns, and deliberately avoids.

Patterns not worth copying now:

- Multi-provider registry.
- WidgetKit.
- Sparkle/update plumbing.
- Cookie or keychain-driven usage providers.
- Dedicated CLI subproduct.
- Immediate AppKit status item migration.

## Kubebar Current State

Kubebar already has the right product foundation:

- `MenuBarExtra.window` app shell.
- `MenuDisplayModel` as the view input.
- `HealthEvaluator` as the severity source.
- `RefreshCoordinator` for snapshot-to-display refresh behavior.
- `AppConfigStore` for app-owned context and watchlist.
- First-use setup and watchlist editing from issue #3.

Observed gaps:

- `scripts/swift-quality-gate.sh local` builds and tests, but it does not launch
  the actual menu bar app or confirm the process stays running.
- Setup/loading behavior still depends heavily on `MenuBarViewModel`; the first
  issue #3 UAT failures show this needs stronger testable state coverage.
- `AppConfig.refreshIntervalSeconds` exists, but refresh cadence is not yet a
  visible, controlled user-facing behavior.
- Current icon mapping is categorical, but it does not yet communicate freshness
  and failure context as deliberately as the rest of the menu.
- Privacy/read-boundary docs do not explicitly say which Kubernetes data is
  read and that secrets are not queried.

## Design Difference Table

| Topic | CodexBar | Kubebar Phase 04 Choice |
| --- | --- | --- |
| Menu shell | AppKit `NSStatusItem` and `NSMenu` | Keep `MenuBarExtra.window` and fix reliability first |
| Data model | Provider registry and usage stores | Keep one Kubernetes reader and one health evaluator |
| First signal | Compact status item state | Preserve `OK`, `Watch`, `Bad`, `Stale` |
| Refresh | Store-owned refresh loop | Add visible cadence and auto-refresh loop around existing config |
| Verification | Build/run scripts and tests | Add local compile-and-run script plus UAT checklist |
| Scope | Usage-monitoring utility | Watchlist-first Kubernetes status utility |

## Plan Mapping

| Lesson | Plan |
| --- | --- |
| Real app launch catches menu bar failures | `04-01` |
| Menu/setup state needs model seams | `04-02` |
| Refresh cadence must be visible and reliable | `04-03` |
| Icon/docs/QA complete the operator loop | `04-04` |

## Recommendation

Proceed with a four-plan phase. Keep each plan small enough to validate with
the Swift quality gate and, where needed, the new launch script.

## RESEARCH COMPLETE
