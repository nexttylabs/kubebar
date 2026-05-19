# Immune-Brain Summary

## 当前状态
- **最新摘要**: Start at Login setting completed
- **待办事项**: No known blockers; code review found no rework,  quality gate and visible setup smoke passed.
- **最后同步**: 2026-05-19 11:58:46

## Knowledge Index

- `docs/solutions/app-settings/start-at-login-boundary-2026-05-19.md`:
  reusable pattern for macOS-only settings that mutate system state through an
  app-target boundary while keeping state transitions testable in KubebarCore.
- `docs/solutions/ui-display/pod-resource-readability-2026-05-14.md`:
  reusable pattern for readable current-snapshot Pod resource labels, explicit
  unavailable resource details, and health non-coupling tests.
- `docs/solutions/rejected-decisions/pod-resource-history-alerting-2026-05-14.md`:
  rejected scope expansion for historical Pod resource trends, metrics storage,
  and resource-pressure alerting inside the readability slice.
