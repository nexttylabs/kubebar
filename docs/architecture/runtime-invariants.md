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

## Freshness Rules

- Old data never looks current.
- A failed refresh may keep the previous snapshot only when the UI marks it
  `Stale`.
- Stale state must show the last successful update and the failure reason when
  one is available.
- If no valid configuration exists, the app shows setup or recovery state
  instead of healthy cluster content.

## Watchlist Rules

- Watchlist rows stay short and readable.
- Tracked item names may truncate, but their meaning should still be clear.
- The watchlist is ordered by attention, not by raw cluster size.
- An empty watchlist is a real state and must not be treated as a healthy
  cluster.

## Failure Rules

- Command failures, parse failures, and timeouts are surfaced as refresh
  failures.
- A refresh failure must never silently clear the last good data.
- Warning and failure states must not rely on color alone.

