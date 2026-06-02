# Immune-Brain Summary

## 当前状态
- **最新摘要**: Closed: release build version metadata sync completed; captured reusable release-tooling guidance for synchronizing release inputs, xcodebuild settings, and packaged Info.plist metadata.
- **待办事项**: Next: work is closed; optional next step is to commit/publish these changes or start a new scoped task.
- **最后同步**: 2026-06-02 09:40:25

## Knowledge Index

- `docs/solutions/release-tooling/release-build-version-metadata-2026-06-02.md`:
  reusable pattern for keeping release version inputs, Xcode build settings, and
  packaged app `Info.plist` metadata synchronized with fake-tool tests and
  post-build verification.
- `docs/solutions/app-settings/start-at-login-boundary-2026-05-19.md`:
  reusable pattern for macOS-only settings that mutate system state through an
  app-target boundary while keeping state transitions testable in KubebarCore.
- `docs/solutions/ui-display/pod-resource-readability-2026-05-14.md`:
  reusable pattern for readable current-snapshot Pod resource labels, explicit
  unavailable resource details, and health non-coupling tests.
- `docs/solutions/rejected-decisions/pod-resource-history-alerting-2026-05-14.md`:
  rejected scope expansion for historical Pod resource trends, metrics storage,
  and resource-pressure alerting inside the readability slice.
