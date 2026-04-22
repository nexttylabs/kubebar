# Runtime Invariants

These are the rules Kubebar must keep true at runtime.

## Product Rules

- The menu bar icon only uses `OK`, `Watch`, `Bad`, or `Stale`.
- `OK` uses the brand logo in the menu bar, but the opened menu must explicitly show OK text.
- The first screen is watchlist-first without requiring a visible `Watching`
  section. Tracked objects must influence the top status row and pinned warning
  ordering.
- The first screen shows the top status row, Nodes card, Pods card, CPU card,
  Memory card, and capped `Recent Warnings`; warning overflow belongs in Events.
- Deep troubleshooting stays out of version 1.

## Data Rules

- `MenuDisplayModel` is the only input the menu uses for rendering.
- `HealthEvaluator` is the single source of truth for severity.
- `AppConfigStore` owns the saved context and watchlist.
- `KubectlClusterReader` always uses the app-owned selected context, not the
  shell context.
- `CommandRunner` remains an injectable boundary so reads can be tested without
  shelling out.
- Kubebar uses `kubectl` only for the saved context and the status/setup reads
  needed by the menu.
- CPU and memory cards use `kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes`
  and node allocatable values. Missing Metrics API data is a card-level
  unavailable state, not a cluster-health failure by itself.
- Nodes tab rows come from `MenuDisplayModel` node display data. They show node
  name, readiness, CPU, and memory without letting the view decide health.
- Not Ready node rows must be distinguishable without relying on color alone
  and must include one short issue description when node condition detail is
  available.
- Node pressure conditions such as `DiskPressure`, `MemoryPressure`, and
  `PIDPressure` are surfaced as node issues even when the `Ready` condition is
  still `True`.
- Missing per-node CPU or memory data shows unavailable values such as `-`;
  missing values must not be rendered as `0`.
- Kubebar does not query Kubernetes Secrets.
- Events warning summaries are capped at 3. Overview `Recent Warnings` is capped
  at 2 visible rows by default so it cannot push the top status row or cards out
  of the first scan.
- Warning summaries are grouped by reason plus involved object. Rows lead with
  reason, then show object scope, age, repeat count, and secondary message text.
- Overview tracked-object warnings must be visibly distinct without using the
  word `Watching`; the distinction must not rely on color alone.
- `Recent Warnings` empty, unavailable, and overflow states must read
  differently. Empty means no warning rows, unavailable means warning data could
  not be read, and overflow means more grouped warnings are in Events.
- Partial section failures must be visible as unavailable and must not make
  unavailable data look healthy.
- Menu views must not show unprocessed command transcripts.
- Kubebar keeps config and displayed cluster status local to the app.
- Context, namespace, workload, and warning names stay app-owned display
  strings; tooltips and accessibility labels must not expose command
  transcripts or JSON.

## Freshness Rules

- Old data never looks current.
- A successful snapshot older than `2x` the saved refresh cadence must be shown
  as `Stale`, even when its counters and watchlist rows were healthy when
  captured.
- A failed refresh may keep the previous snapshot only when the UI marks it
  `Stale`.
- Repeated refresh failures keep the last successful snapshot only as stale data
  and update the safe stale reason without clearing counters or watchlist rows.
- Stale state must show the last successful update and the failure reason when
  one is available.
- If refresh fails before any successful snapshot exists, the stale reason is
  `No previous cluster data`.
- If no valid configuration exists, the app shows setup or recovery state
  instead of healthy cluster content.

## Watchlist Rules

- Watchlist rows stay short and readable.
- Long context, namespace, workload, and warning names use one-line middle
  truncation in views, preserving full names for tooltip and accessibility text.
- Primary watchlist rows stay one line; detailed reasons stay in watchlist
  detail, stale banner, warning event, or section notice areas.
- The watchlist is ordered by attention, not by raw cluster size.
- Overview does not show a separate `Watching` label or section. Tracked-object
  attention remains visible through the top status row and through pinned
  `Recent Warnings` ordering.
- An empty watchlist is a real state and must not be treated as a healthy
  cluster.
- Setup candidate discovery must use the app-owned selected context.
- Watchlist setup candidates include namespaces plus Deployment, StatefulSet,
  DaemonSet, and CronJob workloads.
- Historical Job objects are not default setup candidates.
- Candidate discovery failure must preserve selected targets and show a retry
  path.
- Tracked item details are limited to state, reason, affected pod count, 1-3
  example pod names, and latest related warning.

## Keyboard Rules

- Setup, refresh, edit watchlist, watchlist detail, warning events, and
  secondary sections must be reachable through native macOS keyboard
  navigation.
- Overview keyboard focus order is top status row, Nodes card, Pods card, CPU
  card, Memory card, visible `Recent Warnings` rows, then warning overflow
  affordance when present.
- Refresh and setup completion must keep enabled and disabled states visible
  and testable.
- Keyboard support uses native SwiftUI controls and shortcuts, not custom app
  shell handling.

## Failure Rules

- Timeout, command failure, malformed JSON, and no previous data are distinct
  safe reason categories.
- Timeout uses `kubectl timed out`.
- Empty or unsafe command failure output uses `kubectl failed`.
- Malformed section data uses short reasons such as `invalid node JSON`,
  `invalid pod JSON`, `invalid event JSON`, or `invalid workload JSON`.
- No previous successful data uses `No previous cluster data`.
- A refresh failure must never silently clear the last good data.
- Warning and failure states must not rely on color alone.
- Watch, Bad, and Stale must be expressed with symbol, state text, and one
  short reason; color alone is not enough.
- Stale or failed reads must use distinct icon semantics from `OK`.
