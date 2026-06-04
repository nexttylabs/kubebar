# Immune-Brain Summary

## 当前状态
- **最新摘要**: Closed: captured reusable architecture guidance for per-context watchlists and the menu Quick Context Selector.
- **待办事项**: Next: work is closed; optional next step is to review docs/solutions/architecture/per-context-watchlists-active-context-2026-06-03.md or start a new scoped task.
- **最后同步**: 2026-06-03 11:16:36

## Knowledge Index

- `docs/solutions/release-tooling/release-build-version-metadata-2026-06-02.md`:
  reusable pattern for keeping release version inputs, Xcode build settings, and
  packaged app `Info.plist` metadata synchronized with fake-tool tests and
  post-build verification.
- `docs/solutions/architecture/per-context-watchlists-active-context-2026-06-03.md`:
  reusable pattern for keeping one app-owned active Kubernetes context while
  preserving per-context watchlists, settings tabs, menu switching, and stale
  runtime invalidation.
- `docs/solutions/app-settings/start-at-login-boundary-2026-05-19.md`:
  reusable pattern for macOS-only settings that mutate system state through an
  app-target boundary while keeping state transitions testable in KubebarCore.
- `docs/solutions/ui-display/pod-resource-readability-2026-05-14.md`:
  reusable pattern for readable current-snapshot Pod resource labels, explicit
  unavailable resource details, and health non-coupling tests.
- `docs/solutions/rejected-decisions/pod-resource-history-alerting-2026-05-14.md`:
  rejected scope expansion for historical Pod resource trends, metrics storage,
  and resource-pressure alerting inside the readability slice.
