# Testing Patterns

**Analysis Date:** 2026-04-19

## Test Framework

**Runner:**
- Swift Testing, shipped with the Swift 6 toolchain declared in `Package.swift` and `project.yml`.
- Config: `Package.swift` defines `.testTarget(name: "KubebarCoreTests", dependencies: ["KubebarCore"], path: "KubebarTests")`.
- Config: `project.yml` defines the `KubebarTests` Xcode unit-test target and includes it in the shared `Kubebar` scheme.
- Quality gate: `scripts/swift-quality-gate.sh` runs Xcode build, Xcode test, `swift build`, and `swift test` when both Xcode and SwiftPM project shapes are present.

**Assertion Library:**
- Swift Testing macros from `import Testing`, mainly `#expect(...)` and `#expect(throws:)`, as used in `KubebarTests/Models/MenuDisplayModelTests.swift`, `KubebarTests/Services/ContextCatalogTests.swift`, and `KubebarTests/Services/AppConfigStoreTests.swift`.
- XCTest is not used in current test files under `KubebarTests/`.

**Run Commands:**
```bash
./scripts/swift-quality-gate.sh local  # Run the full local gate from AGENTS.md
swift test                             # Run SwiftPM tests only
xcodebuild -project Kubebar.xcodeproj -scheme Kubebar -configuration Debug -destination 'platform=macOS' test CODE_SIGNING_ALLOWED=NO  # Run Xcode tests
```

- Watch mode: Not detected. No watch command is configured in `Package.swift`, `project.yml`, `scripts/swift-quality-gate.sh`, or `.github/workflows/ci.yml`.
- CI command: `.github/workflows/ci.yml` runs `./scripts/swift-quality-gate.sh ci` on pull requests to `main`.

## Test File Organization

**Location:**
- Tests are separate from production code under `KubebarTests/`.
- Model tests live in `KubebarTests/Models/`, mirroring `KubebarCore/Models/`.
- Service tests live in `KubebarTests/Services/`, mirroring `KubebarCore/Services/`.
- No UI snapshot or interaction tests are present for `Kubebar/Views/` or `Kubebar/MenuBarViewModel.swift`.

**Naming:**
- Test files use `<Subject>Tests.swift`, such as `KubebarTests/Models/ClusterHealthStateTests.swift`, `KubebarTests/Models/MenuDisplayModelTests.swift`, and `KubebarTests/Services/KubectlClusterReaderTests.swift`.
- Test suites use `@Suite("Human readable subject")`, as in `@Suite("Menu display model")` in `KubebarTests/Models/MenuDisplayModelTests.swift`.
- Test cases use `@Test("behavior statement")` with lowerCamelCase function names, as in `@Test("failed refresh keeps previous data but marks it stale")` and `failedRefreshKeepsPreviousDataButMarksItStale()` in `KubebarTests/Models/MenuDisplayModelTests.swift`.

**Structure:**
```text
KubebarTests/
+-- Models/      # Tests for pure value models and display mapping in KubebarCore/Models/
+-- Services/    # Tests for service boundaries, config persistence, refresh behavior, and kubectl reading
```

## Test Structure

**Suite Organization:**
Use this Swift Testing pattern from `KubebarTests/Services/ContextCatalogTests.swift`:

```swift
import Testing
@testable import KubebarCore

@Suite("Context catalog")
struct ContextCatalogTests {
    @Test("lists kubectl contexts from command output")
    func listsKubectlContextsFromCommandOutput() throws {
        let runner = FakeCommandRunner(result: CommandResult(stdout: "prod\nstaging\n\n", stderr: "", exitCode: 0))
        let catalog = ContextCatalog(runner: runner)

        #expect(try catalog.listContexts() == ["prod", "staging"])
        #expect(runner.lastRequest?.executable == "kubectl")
    }
}
```

**Patterns:**
- Arrange values inline at the top of each test, act once, then assert concrete output fields. `KubebarTests/Models/MenuDisplayModelTests.swift` constructs `ClusterSnapshot`, calls `HealthEvaluator().evaluate(...)`, and asserts the resulting `MenuDisplayModel`.
- Use deterministic dates instead of `Date()` when asserting time-derived output. `KubebarTests/Models/MenuDisplayModelTests.swift` and `KubebarTests/Services/RefreshCoordinatorTests.swift` use `Date(timeIntervalSince1970:)`.
- Use `throws` on tests that call throwing APIs directly, as in `KubebarTests/Services/KubectlClusterReaderTests.swift`, `KubebarTests/Services/CommandRunnerTests.swift`, and `KubebarTests/Services/AppConfigStoreTests.swift`.
- Use `#expect(throws:)` for expected errors, as in `KubebarTests/Services/ContextCatalogTests.swift` and `KubebarTests/Services/AppConfigStoreTests.swift`.
- Keep fakes local to the test file and mark them `private`, as in `FakeCommandRunner` in `KubebarTests/Services/ContextCatalogTests.swift` and `FakeClusterReader` in `KubebarTests/Services/RefreshCoordinatorTests.swift`.

## Mocking

**Framework:** Manual fakes. No mocking framework is detected in `Package.swift`, `project.yml`, or `KubebarTests/`.

**Patterns:**
Use protocol-backed fakes for command and reader boundaries, as in `KubebarTests/Services/RefreshCoordinatorTests.swift`:

```swift
private struct FakeClusterReader: ClusterReading {
    let result: Result<ClusterSnapshot, Error>

    func readSnapshot(contextName: String, watchTargets: [WatchTarget], now: Date) throws -> ClusterSnapshot {
        try result.get()
    }
}
```

Use command-output lookup fakes for `kubectl` behavior, as in `KubebarTests/Services/KubectlClusterReaderTests.swift`:

```swift
private final class FakeMultiCommandRunner: CommandRunning, @unchecked Sendable {
    private let results: [[String]: CommandResult]

    init(results: [[String]: CommandResult]) {
        self.results = results
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        results[request.arguments] ?? CommandResult(stdout: "", stderr: "unexpected command", exitCode: 1)
    }
}
```

**What to Mock:**
- Mock external command execution through `CommandRunning`, as in `KubebarTests/Services/KubectlClusterReaderTests.swift` and `KubebarTests/Services/ContextCatalogTests.swift`.
- Mock cluster reads through `ClusterReading`, as in `KubebarTests/Services/RefreshCoordinatorTests.swift`.
- Use temporary directories for filesystem writes, as in `makeTemporaryDirectory()` in `KubebarTests/Services/AppConfigStoreTests.swift`.
- Use static JSON strings for kubectl fixtures inside the relevant test file, as in `nodesJSON`, `podsJSON`, and `warningEventsJSON` in `KubebarTests/Services/KubectlClusterReaderTests.swift`.

**What NOT to Mock:**
- Do not mock pure value transformations. Test `HealthEvaluator` and model computed properties directly, as in `KubebarTests/Models/MenuDisplayModelTests.swift`, `KubebarTests/Models/SetupFlowStateTests.swift`, and `KubebarTests/Models/WatchlistSelectionStateTests.swift`.
- Do not shell out to real `kubectl` in unit tests. `KubebarCore/Services/CommandRunner.swift` is covered separately by `KubebarTests/Services/CommandRunnerTests.swift`, while `KubebarCore/Services/KubectlClusterReader.swift` uses fake runners.
- Do not depend on the terminal's current Kubernetes context. Production code uses app-owned context values in `KubebarCore/Services/KubectlClusterReader.swift`, and tests pass `contextName: "prod"` explicitly.

## Fixtures and Factories

**Test Data:**
Use inline domain values for small model tests, as in `KubebarTests/Models/MenuDisplayModelTests.swift`:

```swift
let snapshot = ClusterSnapshot(
    contextName: "prod",
    nodeSummary: NodeSummary(ready: 3, total: 3),
    podSummary: PodSummary(running: 12, total: 12),
    warningEventCount: 0,
    trackedItems: [
        TrackedItemStatus(target: .workload(namespace: "api", name: "checkout"), state: .ok, reason: "6/6 pods running")
    ],
    capturedAt: Date(timeIntervalSince1970: 100)
)
```

Use inline JSON strings for kubectl parser coverage, as in `KubebarTests/Services/KubectlClusterReaderTests.swift`:

```swift
private let nodesJSON = """
{
  "items": [
    {"status": {"conditions": [{"type": "Ready", "status": "True"}]}}
  ]
}
"""
```

**Location:**
- Fixtures are currently co-located in the test file that uses them, such as `KubebarTests/Services/KubectlClusterReaderTests.swift`.
- No shared fixture directory or factory module is detected under `KubebarTests/`.
- Add shared factories only when duplication becomes meaningful across several test files; otherwise keep fixtures local and private like the existing tests.

## Coverage

**Requirements:** Codecov status is configured but local coverage generation is not.
- `codecov.yml` sets project coverage target to 80% with a 2% threshold.
- `codecov.yml` sets patch coverage target to 90%.
- `.github/workflows/ci.yml` does not upload coverage, and `scripts/swift-quality-gate.sh` does not enable coverage.

**View Coverage:**
```bash
# Not configured in this repository.
# The supported verification command is:
./scripts/swift-quality-gate.sh local
```

## Test Types

**Unit Tests:**
- Primary test type. Use for health states, display mapping, setup state, watchlist selection, config persistence, command running, context parsing, kubectl JSON parsing, and refresh coordination in `KubebarTests/Models/*.swift` and `KubebarTests/Services/*.swift`.
- Unit tests assert product invariants from `docs/architecture/runtime-invariants.md`, especially stale-data behavior, fixed health labels, watchlist cap, and app-owned context reads.

**Integration Tests:**
- Lightweight integration exists through `ProcessCommandRunner` exercising real `/bin/sh` output behavior in `KubebarTests/Services/CommandRunnerTests.swift`.
- `scripts/swift-quality-gate.sh` provides build-and-test integration across Xcode and SwiftPM.
- `tests/swift_template_support.sh` tests repository template support and quality gate detection with stubbed `swift` and `xcodebuild` commands.

**E2E Tests:**
- Not used. No UI automation, simulator, menu bar interaction, or snapshot testing is configured in `Package.swift`, `project.yml`, `KubebarTests/`, or `.github/workflows/`.

## Common Patterns

**Async Testing:**
Current core APIs are mostly synchronous. Concurrency is tested by observing behavior through a fake runner, as in `KubebarTests/Services/KubectlClusterReaderTests.swift`:

```swift
@Test("reads independent kubectl resources concurrently")
func readsIndependentKubectlResourcesConcurrently() throws {
    let runner = SlowRecordingCommandRunner(results: [
        ["--context", "prod", "get", "nodes", "-o", "json"]: CommandResult(stdout: nodesJSON, stderr: "", exitCode: 0)
    ])
    let reader = KubectlClusterReader(runner: runner)

    _ = try reader.readSnapshot(
        contextName: "prod",
        watchTargets: [.workload(namespace: "api", name: "checkout")],
        now: Date(timeIntervalSince1970: 100)
    )

    #expect(runner.maximumConcurrentRequests > 1)
}
```

**Error Testing:**
Use `#expect(throws:)` with exact domain errors, as in `KubebarTests/Services/ContextCatalogTests.swift`:

```swift
#expect(throws: KubectlCommandError.failed("no kubeconfig")) {
    try catalog.listContexts()
}
```

Use stale-display assertions for recoverable refresh failures, as in `KubebarTests/Services/RefreshCoordinatorTests.swift`:

```swift
#expect(result.snapshot == previous)
#expect(result.display.state == .stale)
#expect(result.display.staleBanner?.reason == "cluster unreachable")
```

## Regression Enforcement

- Local commit hook `.githooks/commit-msg` requires test changes for `fix:`, `hotfix:`, or `bugfix:` commits unless `[skip-regression-check]` is present.
- CI workflow `.github/workflows/regression-test-check.yml` applies the same regression-test rule to fix pull requests unless the `skip-regression-check` label is present.
- The regression checker detects Swift test files by path and file name patterns, so place regression tests in `KubebarTests/` or use a `*Tests.swift`, `*Spec.swift`, or `*SnapshotTests.swift` suffix.

---

*Testing analysis: 2026-04-19*
