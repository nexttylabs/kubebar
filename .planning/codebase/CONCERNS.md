# Codebase Concerns

**Analysis Date:** 2026-04-19

## Tech Debt

**First-use watchlist target discovery:**
- Issue: The setup state can represent available namespaces and workloads, but the live app only loads context names. `WatchlistPickerView` exposes "Add namespace" and "Add workload" buttons whose default callbacks do nothing.
- Files: `Kubebar/MenuBarViewModel.swift`, `Kubebar/Views/SetupView.swift`, `Kubebar/Views/WatchlistPickerView.swift`, `KubebarCore/Models/WatchlistSelectionState.swift`, `KubebarCore/Services/ContextCatalog.swift`
- Impact: A clean first launch cannot build a watchlist through the app UI, so setup cannot reach the configured state without an existing config file or test-only state injection.
- Fix approach: Add an injectable watch target catalog that reads namespaces and supported workload names for the selected context, wire it through `MenuBarViewModel`, and make the setup view update available targets when the selected context changes.

**Freshness model without age-out:**
- Issue: `AppConfig.refreshIntervalSeconds` is saved, but there is no scheduler, no periodic refresh task, and no stale threshold applied to an old successful snapshot.
- Files: `KubebarCore/Services/AppConfigStore.swift`, `Kubebar/MenuBarViewModel.swift`, `KubebarCore/Services/HealthEvaluator.swift`, `KubebarCore/Services/RefreshCoordinator.swift`, `docs/architecture/runtime-invariants.md`
- Impact: A successful `OK` display can remain visible indefinitely when the app is open and no manual refresh happens, which weakens the invariant that old data never looks current.
- Fix approach: Own a refresh task in `MenuBarViewModel`, use `refreshIntervalSeconds`, add a max-age rule in `HealthEvaluator`, and cancel/reschedule the task when config changes.

**All-or-nothing cluster reads:**
- Issue: `KubectlClusterReader` launches node, pod, and warning event reads concurrently, then throws if any read fails.
- Files: `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarCore/Services/RefreshCoordinator.swift`, `KubebarTests/Services/KubectlClusterReaderTests.swift`, `KubebarTests/Services/RefreshCoordinatorTests.swift`
- Impact: A permissions or parsing problem in one section makes the entire menu stale even when other sections are readable.
- Fix approach: Return structured partial results with per-section failures, keep successful sections fresh, and let `HealthEvaluator` mark unavailable sections without discarding the whole snapshot.

**Coarse Kubernetes health parsing:**
- Issue: Pod health only checks `status.phase == "Running"`, workload matching only checks exact pod name plus `app.kubernetes.io/name` and `app` labels, and warning events are reduced to a count.
- Files: `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarCore/Models/ClusterSnapshot.swift`, `KubebarCore/Models/WatchTarget.swift`, `Kubebar/Views/WarningEventsView.swift`, `Kubebar/Views/TrackedItemDetailView.swift`
- Impact: Running but unready pods can look healthy, common Kubernetes controller names can miss their pods, and warning rows cannot explain reason, object, namespace, or time.
- Fix approach: Decode pod conditions, container statuses, restart counts, owner references, and event fields; map them into richer snapshot fields while keeping UI rendering behind `MenuDisplayModel`.

**Config recovery path:**
- Issue: `AppConfigStore.load()` reports corrupt config, but `MenuBarViewModel` catches all load errors and silently resets to an empty `AppConfig`.
- Files: `KubebarCore/Services/AppConfigStore.swift`, `Kubebar/MenuBarViewModel.swift`, `KubebarTests/Services/AppConfigStoreTests.swift`
- Impact: A malformed saved config presents as first-use setup with no reason, and the app gives the user no recovery message or location of the bad file.
- Fix approach: Preserve the recoverable error in setup state, show a clear recovery message, and keep the corrupt file intact until the user saves a replacement config.

**Template-era support scripts:**
- Issue: The repository contains generic setup and Rust panic-check tooling that is not used by the Swift quality gate.
- Files: `scripts/dev-setup.sh`, `scripts/check_no_panics.py`, `AGENTS.md`, `README.md`
- Impact: Contributors can see unrelated Rust, TypeScript, Go, and Python setup paths while the product is a Swift/macOS app.
- Fix approach: Keep `dev-setup.sh` if it remains the repo bootstrapper, but remove or archive unused language checks that do not participate in the Kubebar quality gate.

## Known Bugs

**Clean first launch cannot complete setup through the UI:**
- Symptoms: The setup screen can list contexts, but it has no live namespace or workload choices; the add buttons have no behavior; "Finish setup" stays disabled while the watchlist is empty.
- Files: `Kubebar/MenuBarViewModel.swift`, `Kubebar/Views/SetupView.swift`, `Kubebar/Views/WatchlistPickerView.swift`, `KubebarCore/Models/SetupFlowState.swift`, `KubebarCore/Models/WatchlistSelectionState.swift`
- Trigger: Launch the app with no saved `config.json`, open setup, select a context, and try to add a namespace or workload.
- Workaround: Create a config through code/tests or implement target discovery before relying on the setup flow.

**Successful data has no freshness timeout:**
- Symptoms: A successful snapshot keeps the previous `OK`, `Watch`, or `Bad` state until another refresh fails or succeeds.
- Files: `Kubebar/MenuBarViewModel.swift`, `KubebarCore/Services/HealthEvaluator.swift`, `KubebarCore/Services/RefreshCoordinator.swift`, `KubebarCore/Models/ClusterSnapshot.swift`
- Trigger: Complete a successful refresh, leave the app idle past the intended refresh cadence, and do not press "Retry now".
- Workaround: Use manual refresh as the only freshness control until scheduled refresh and max-age evaluation exist.

**Overlapping manual refreshes can overwrite newer state:**
- Symptoms: Each `refreshNow()` call creates an untracked `Task`; slower earlier requests and faster later requests can finish in either order and both assign `snapshot` and `display`.
- Files: `Kubebar/MenuBarViewModel.swift`, `KubebarCore/Services/RefreshCoordinator.swift`, `KubebarCore/Services/KubectlClusterReader.swift`
- Trigger: Press "Retry now" repeatedly while `kubectl` is slow, timing out, or intermittently failing.
- Workaround: Avoid repeated manual refresh clicks until the view model tracks a refresh task, serializes requests, or discards stale completions.

**Regression-test workflow YAML has unindented script lines:**
- Symptoms: The Swift test-detection block is outside the `run: |` indentation level, which makes the workflow file structurally invalid or changes the intended script body.
- Files: `.github/workflows/regression-test-check.yml`
- Trigger: GitHub Actions loads the `Regression Test Check` workflow for a pull request.
- Workaround: Use the `skip-regression-check` label on the pull request to bypass the failing check until the indentation is corrected.

**Overflow watchlist entry is inert text:**
- Symptoms: The menu shows "View all tracked" when hidden items exist, but it is a `Text` view with no action or expanded list.
- Files: `Kubebar/Views/WatchlistSectionView.swift`, `KubebarCore/Services/HealthEvaluator.swift`, `KubebarCore/Models/MenuDisplayModel.swift`
- Trigger: Use more than five configured watch targets.
- Workaround: Keep watchlists at five or fewer items until the overflow row opens a secondary view or expanded section.

## Security Considerations

**kubectl executable resolution through PATH:**
- Risk: `ProcessCommandRunner` runs `/usr/bin/env` with `kubectl`, so executable choice depends on the app process environment.
- Files: `KubebarCore/Services/CommandRunner.swift`, `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarCore/Services/ContextCatalog.swift`
- Current mitigation: The code passes arguments as an array, so context and target names are not shell-interpolated.
- Recommendations: Resolve and store an absolute `kubectl` path, validate the executable during setup, and show a recovery message when the binary cannot be found.

**Raw kubectl stderr appears in UI state:**
- Risk: Command errors flow from `stderr` into `KubectlCommandError.failed`, then into the stale banner reason.
- Files: `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarCore/Services/ContextCatalog.swift`, `KubebarCore/Services/RefreshCoordinator.swift`, `Kubebar/Views/StaleBannerView.swift`
- Current mitigation: Only stderr text is shown; stdout JSON is not displayed.
- Recommendations: Redact likely paths, tokens, kubeconfig details, and multi-line command output before assigning user-facing failure reasons.

**Local config file permissions are implicit:**
- Risk: Saved context and watchlist are written with default filesystem permissions.
- Files: `KubebarCore/Services/AppConfigStore.swift`, `Kubebar/MenuBarViewModel.swift`
- Current mitigation: The config stores context and target names, not Kubernetes credentials.
- Recommendations: Create the application support directory with owner-only permissions where possible and avoid expanding config to secrets.

**Full-cluster read scope:**
- Risk: The app reads pods and warning events across all namespaces even when the watchlist is small.
- Files: `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarCore/Models/WatchTarget.swift`
- Current mitigation: Reads use the app-owned selected context and do not mutate cluster state.
- Recommendations: Prefer namespace-scoped reads for namespace targets and selector-based reads for workload targets, then keep only aggregate display data in memory.

## Performance Bottlenecks

**Full-cluster pod and event snapshots:**
- Problem: Every snapshot runs `kubectl get pods --all-namespaces -o json` and `kubectl get events --all-namespaces --field-selector type=Warning -o json`.
- Files: `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarCore/Services/CommandRunner.swift`
- Cause: The reader builds global summaries first and filters watch targets in memory.
- Improvement path: Query only selected namespaces and workloads where possible, keep global counters optional, and add performance tests with large JSON fixtures.

**Process startup per resource:**
- Problem: Each refresh starts three subprocesses.
- Files: `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarCore/Services/CommandRunner.swift`
- Cause: `KubectlRead.allCases` maps to independent `kubectl` commands.
- Improvement path: Keep the concurrent reads for small clusters, but measure command latency and consider command grouping or incremental APIs if polling becomes noisy.

**Unbounded in-memory output buffering:**
- Problem: stdout and stderr are read fully into memory before parsing.
- Files: `KubebarCore/Services/CommandRunner.swift`, `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarTests/Services/CommandRunnerTests.swift`
- Cause: `LockedDataBuffer` stores complete `Data` for each stream.
- Improvement path: Add output size limits for command failures and large fixture tests for successful JSON decoding.

**Repeated refresh overlap:**
- Problem: Manual refreshes can run concurrently and multiply the number of active `kubectl` processes.
- Files: `Kubebar/MenuBarViewModel.swift`, `Kubebar/Views/MenuBarRootView.swift`, `KubebarCore/Services/KubectlClusterReader.swift`
- Cause: `refreshNow()` has no in-flight guard, debounce, cancellation, or result generation check.
- Improvement path: Track the active refresh task, disable the retry action while a refresh is running, and ignore completions from older generations.

## Fragile Areas

**View model async lifecycle:**
- Files: `Kubebar/MenuBarViewModel.swift`, `KubebarCore/Services/RefreshCoordinator.swift`
- Why fragile: The view model mutates main-actor state after detached work without tracking task lifetime, cancellation, generation, or app shutdown.
- Safe modification: Add a stored task handle, isolate refresh state transitions, and test ordering with a controllable fake reader.
- Test coverage: No tests target `MenuBarViewModel`.

**Manual Sendable wrappers and locking:**
- Files: `KubebarCore/Services/CommandRunner.swift`, `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarTests/Services/KubectlClusterReaderTests.swift`
- Why fragile: `@unchecked Sendable`, `NSLock`, `DispatchGroup`, and `DispatchSemaphore` require discipline outside Swift's checked concurrency model.
- Safe modification: Keep the locking boundary tiny, prefer async APIs for new code, and add tests that cover timeout, cancellation, and concurrent failure ordering.
- Test coverage: Tests cover concurrent reads and large output, but not cancellation, subprocess tree termination, or mixed success/failure ordering.

**Health priority depends on enum raw values:**
- Files: `KubebarCore/Models/ClusterHealthState.swift`, `KubebarCore/Services/HealthEvaluator.swift`, `KubebarTests/Models/MenuDisplayModelTests.swift`
- Why fragile: Watchlist sorting uses `state.rawValue >` as priority, tying UI attention order to enum storage values.
- Safe modification: Add an explicit `attentionPriority` property and test the order for `bad`, `stale`, `watch`, and `ok`.
- Test coverage: Tests cover bad-before-ok, but not every state ordering combination.

**UI behavior is mostly untested:**
- Files: `Kubebar/Views/MenuBarRootView.swift`, `Kubebar/Views/SetupView.swift`, `Kubebar/Views/WatchlistPickerView.swift`, `Kubebar/Views/WatchlistSectionView.swift`, `KubebarTests`
- Why fragile: The documented requirements include keyboard navigation, setup completion, stale banner visibility, and watchlist overflow behavior, but tests target models and services.
- Safe modification: Add view model tests first, then add snapshot or UI-level checks for the menu states that carry product trust.
- Test coverage: No `KubebarTests/Views` directory is present.

**CI workflow script embedding:**
- Files: `.github/workflows/regression-test-check.yml`
- Why fragile: Shell code inside YAML is indentation-sensitive, and the current test-detection block has no `run: |` indentation.
- Safe modification: Move the script to `.github/scripts/` and call it from the workflow, or add a YAML lint step.
- Test coverage: No workflow lint or local CI validation script is present.

## Scaling Limits

**Cluster size:**
- Current capacity: One refresh starts three `kubectl` commands and holds full node, pod, and warning-event JSON in memory.
- Limit: Large clusters, high warning-event counts, or slow API servers can hit the default 10-second command timeout.
- Scaling path: Use scoped reads, selector-based queries, output limits, and incremental refresh options.
- Files: `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarCore/Services/CommandRunner.swift`

**Watchlist size:**
- Current capacity: First-screen display shows five items by default.
- Limit: More than five configured targets only produce an inert overflow label.
- Scaling path: Add a real overflow view, search/filter for setup, and preserve attention ordering in expanded views.
- Files: `KubebarCore/Services/HealthEvaluator.swift`, `Kubebar/Views/WatchlistSectionView.swift`, `KubebarCore/Models/MenuDisplayModel.swift`

**Refresh concurrency:**
- Current capacity: No explicit cap on concurrent manual refresh tasks.
- Limit: Repeated retry actions can run many `kubectl` commands and assign stale results out of order.
- Scaling path: Serialize refreshes and expose in-progress state to the UI.
- Files: `Kubebar/MenuBarViewModel.swift`, `Kubebar/Views/MenuBarRootView.swift`

**Configuration model:**
- Current capacity: One selected context, one array of watch targets, and one integer refresh interval.
- Limit: No validation for refresh interval bounds, no migration version, and no recovery message for malformed config.
- Scaling path: Add config versioning, validation, and explicit recovery state before adding new fields.
- Files: `KubebarCore/Services/AppConfigStore.swift`, `KubebarCore/Models/WatchTarget.swift`, `Kubebar/MenuBarViewModel.swift`

## Dependencies at Risk

**kubectl:**
- Risk: The app requires `kubectl` to exist in the runtime PATH and to return expected JSON fields.
- Impact: Missing `kubectl`, incompatible output, RBAC restrictions, or launchd PATH differences make setup or refresh fail.
- Migration plan: Add setup-time executable validation, an absolute path setting, richer error messages, and fixtures for Kubernetes output variants.
- Files: `KubebarCore/Services/CommandRunner.swift`, `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarCore/Services/ContextCatalog.swift`

**XcodeGen and generated project:**
- Risk: `project.yml` is the source for `Kubebar.xcodeproj`, while `Package.swift` also defines targets.
- Impact: Target settings can drift between Swift Package Manager and the generated Xcode project.
- Migration plan: Treat `project.yml` as the app-project source, add a check that regenerated project output is clean, and keep `Package.swift` limited to package-compatible targets.
- Files: `project.yml`, `Package.swift`, `Kubebar.xcodeproj`, `README.md`, `scripts/swift-quality-gate.sh`

**GitHub Actions macOS image:**
- Risk: CI uses `macos-latest`, which can move Xcode and Swift versions.
- Impact: Builds can change behavior without a repository change.
- Migration plan: Pin a macOS image and Xcode version when release readiness matters.
- Files: `.github/workflows/ci.yml`, `project.yml`, `Package.swift`

**Codecov configuration without upload workflow:**
- Risk: Coverage thresholds exist, but no workflow step uploads coverage.
- Impact: Coverage expectations may look enforced when CI does not publish coverage data.
- Migration plan: Add coverage generation and upload, or remove `codecov.yml` until coverage is wired.
- Files: `codecov.yml`, `.github/workflows/ci.yml`, `scripts/swift-quality-gate.sh`

## Missing Critical Features

**Watch target catalog:**
- Problem: No code lists namespaces or workload candidates for setup.
- Blocks: First-use setup, watchlist editing, and trustworthy user onboarding.
- Files: `Kubebar/MenuBarViewModel.swift`, `Kubebar/Views/WatchlistPickerView.swift`, `KubebarCore/Services/ContextCatalog.swift`

**Scheduled refresh and stale threshold:**
- Problem: Refresh is initial/manual only, and old success states have no age-based stale transition.
- Blocks: Daily use as a trustworthy status instrument.
- Files: `Kubebar/MenuBarViewModel.swift`, `KubebarCore/Services/AppConfigStore.swift`, `KubebarCore/Services/HealthEvaluator.swift`

**Actionable warning and workload reasons:**
- Problem: Warning events are only counted and workload health is reduced to running pod counts.
- Blocks: The menu's ability to answer what needs attention without opening another tool.
- Files: `KubebarCore/Services/KubectlClusterReader.swift`, `Kubebar/Views/WarningEventsView.swift`, `Kubebar/Views/TrackedItemDetailView.swift`

**Operator-facing app verification:**
- Problem: Tests do not exercise the real menu window, keyboard navigation, setup completion, or visual stale states.
- Blocks: Confidence that the macOS app communicates the core trust states correctly.
- Files: `Kubebar/Views/MenuBarRootView.swift`, `Kubebar/Views/SetupView.swift`, `KubebarTests`

## Test Coverage Gaps

**Setup integration:**
- What's not tested: Loading contexts, selecting a context, populating available targets, selecting watch targets, saving config, and leaving setup through `MenuBarViewModel`.
- Files: `Kubebar/MenuBarViewModel.swift`, `Kubebar/Views/SetupView.swift`, `Kubebar/Views/WatchlistPickerView.swift`, `KubebarTests/Models/SetupFlowStateTests.swift`, `KubebarTests/Models/WatchlistSelectionStateTests.swift`
- Risk: The state model tests pass while the app setup path remains unusable.
- Priority: High

**Freshness and refresh scheduling:**
- What's not tested: Automatic refresh cadence, max-age stale transition, refresh cancellation, and repeated manual refresh ordering.
- Files: `Kubebar/MenuBarViewModel.swift`, `KubebarCore/Services/RefreshCoordinator.swift`, `KubebarCore/Services/HealthEvaluator.swift`, `KubebarTests/Services/RefreshCoordinatorTests.swift`
- Risk: Stale or out-of-order data can overwrite the user's current understanding.
- Priority: High

**Kubernetes parser edge cases:**
- What's not tested: Empty pod lists, malformed pod JSON, malformed event JSON, timeout propagation, container readiness, restart counts, owner references, warning event details, and RBAC failures for only one resource type.
- Files: `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarTests/Services/KubectlClusterReaderTests.swift`
- Risk: Common real-cluster states can be misclassified or collapsed into generic stale errors.
- Priority: High

**Command runner failure behavior:**
- What's not tested: Timeout process-tree cleanup, stderr redaction, non-UTF8 output, massive error output, and launchd-like PATH differences.
- Files: `KubebarCore/Services/CommandRunner.swift`, `KubebarTests/Services/CommandRunnerTests.swift`
- Risk: Refreshes can hang, leak subprocesses, or surface unhelpful error text.
- Priority: Medium

**View and accessibility states:**
- What's not tested: Menu bar icon readability, stale banner presentation, keyboard navigation, inert overflow row behavior, and setup button reachability.
- Files: `Kubebar/KubebarApp.swift`, `Kubebar/Views/MenuBarRootView.swift`, `Kubebar/Views/StaleBannerView.swift`, `Kubebar/Views/WatchlistSectionView.swift`, `KubebarTests`
- Risk: The product can satisfy model tests while failing the actual menu-bar workflow.
- Priority: Medium

**CI and workflow validity:**
- What's not tested: YAML syntax, action script indentation, and whether coverage settings are enforced.
- Files: `.github/workflows/regression-test-check.yml`, `.github/workflows/ci.yml`, `codecov.yml`
- Risk: Review and quality gates can fail before tests run or silently skip intended checks.
- Priority: Medium

---

*Concerns audit: 2026-04-19*
