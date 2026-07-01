# Immune-Brain Summary

## 当前状态
- **最新摘要**: Settings UI polish applied: merged AI sections, hidden Base URL for non-compatible providers, replaced invalid SF Symbol, added keyboard shortcuts, context watchlist warning icon, and wider fields.
- **待办事项**: Next: work is closed; HITL Settings smoke recommended to confirm visual layout quality; optional next step is a new scoped task.
- **最后同步**: 2026-07-01 19:00:00

## Knowledge Index

- `docs/solutions/release-tooling/release-build-version-metadata-2026-06-02.md`:
  reusable pattern for keeping release version inputs, Xcode build settings, and
  packaged app `Info.plist` metadata synchronized with fake-tool tests and
  post-build verification.
- `docs/solutions/architecture/per-context-watchlists-active-context-2026-06-03.md`:
  reusable pattern for keeping one app-owned active Kubernetes context while
  preserving per-context watchlists, settings tabs, menu switching, and stale
  runtime invalidation.
- `docs/solutions/architecture/pod-log-focus-window-2026-06-22.md`:
  reusable pattern for menu-launched troubleshooting surfaces that need a
  focusable app-owned macOS window, ViewModel-owned side effects, and native
  read-only text behavior for live logs.
- `docs/solutions/app-settings/start-at-login-boundary-2026-05-19.md`:
  reusable pattern for macOS-only settings that mutate system state through an
  app-target boundary while keeping state transitions testable in KubebarCore.
- `docs/solutions/ui-display/pod-resource-readability-2026-05-14.md`:
  reusable pattern for readable current-snapshot Pod resource labels, explicit
  unavailable resource details, and health non-coupling tests.
- `docs/solutions/rejected-decisions/pod-resource-history-alerting-2026-05-14.md`:
  rejected scope expansion for historical Pod resource trends, metrics storage,
  and resource-pressure alerting inside the readability slice.
- `docs/solutions/app-settings/settings-sidebar-layout-2026-07-01.md`:
  reusable pattern for refactoring a stacked Settings TabView into a
  sidebar/detail layout with grouped App pages, enum expansion without
  breaking callers, and dedicated navigation callback chains.
