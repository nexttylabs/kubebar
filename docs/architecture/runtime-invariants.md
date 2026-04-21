# Runtime Invariants

These are the rules Kubebar must keep true at runtime.

## Product Rules

- The menu bar icon only uses `OK`, `Watch`, `Bad`, or `Stale`.
- The first screen is watchlist-first.
- The first screen shows only a small set of tracked items, with overflow
  pushed behind a secondary entry.
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
- Kubebar does not query Kubernetes Secrets.
- Warning summaries are capped at 3, grouped by reason plus involved object,
  and show only reason, location, age, count, and short message.
- Partial section failures must be visible as unavailable and must not make
  unavailable data look healthy.
- Menu views must not show raw kubectl output.
- Kubebar keeps config and displayed cluster status local to the app.

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
- Tracked item names may truncate, but their meaning should still be clear.
- The watchlist is ordered by attention, not by raw cluster size.
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
- Stale or failed reads must use distinct icon semantics from `OK`.
