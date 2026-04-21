# Phase 03: Complete first-use setup and watchlist editing - Research

**Date:** 2026-04-20
**Status:** Complete
**Source issue:** https://github.com/nexttylabs/kubebar/issues/3

## Research Question

What does the planner need to know to complete first-use setup and watchlist
editing without breaking Kubebar's app-owned context and thin UI boundaries?

## Key Findings

### Kubernetes Discovery Shape

- `kubectl get` supports JSON output through `-o json` and supports
  `--all-namespaces` for namespaced resources.
- Kubebar should keep using `--context <selected-context>` for every discovery
  read. This preserves the app-owned context rule.
- Namespaces can be discovered with:
  `kubectl --context <context> get namespaces -o json`.
- Workload candidates can be discovered with separate commands for:
  - `deployments`
  - `statefulsets`
  - `daemonsets`
  - `cronjobs`
- Do not query `jobs` for first-use candidates. `CronJob` is the durable
  scheduled object; individual `Job` objects are often historical run output.

### Existing App Fit

- `ContextCatalog` already owns context discovery through `CommandRunning`.
  Watch target discovery should use the same boundary style rather than
  placing `kubectl` reads in SwiftUI views.
- `WatchlistSelectionState` already separates available targets from selected
  targets. It can evolve into a candidate-backed state without changing the
  setup screen's overall shape.
- `SetupView` already has context picker, watchlist picker, and finish action.
  The missing piece is candidate loading and error state inside the watchlist
  area.
- `MenuBarViewModel.openSetup()` already starts context loading and
  `completeSetup()` already persists config and refreshes. Context selection
  should trigger candidate loading before finish.

### Model Implications

- Workload candidates need a kind so setup can show `Deployment`,
  `StatefulSet`, `DaemonSet`, and `CronJob` distinctly.
- Saved watch targets should either include workload kind or have a dedicated
  candidate key that prevents same-namespace same-name collisions. The safer
  plan is to add a `WorkloadKind` to workload watch targets and preserve
  backward decoding for older config that has no kind.
- Candidate loading state belongs in setup state, not in the view. The view can
  render `.idle`, `.loading`, and `.failed(reason)` states.

### Test Strategy

- Service tests should use fake `CommandRunning` values and inline JSON, like
  existing `KubectlClusterReaderTests`.
- Model tests should cover candidate grouping, selected target preservation,
  and setup readiness.
- Save failure should remain user-visible through `configurationMessage`.
- Verification should end with `./scripts/swift-quality-gate.sh local`.

## External References

- Kubernetes `kubectl get`: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_get/
- Kubernetes workload controllers: https://kubernetes.io/docs/concepts/workloads/controllers/
- Kubernetes CronJob: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
- Kubernetes DaemonSet: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/
- Kubernetes StatefulSet: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/

## Planning Risks

| Risk | Plan response |
| --- | --- |
| Candidate discovery reads the terminal's current context | Require every discovery command to include `--context <selected-context>` |
| Historical Jobs make setup noisy | Exclude `jobs`; include `cronjobs` |
| Same-named workloads collide | Include workload kind in candidate/target identity |
| Candidate load failure loses selections | Keep selected targets while showing failure + retry |
| UI grows into a dashboard | Reuse setup screen and keep loading/error state inside watchlist area |

## Validation Notes

No separate validation architecture is needed for this phase. The behavior is
covered by service/model tests, existing app quality gate, and issue #3
acceptance criteria.
