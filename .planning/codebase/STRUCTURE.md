# Codebase Structure

**Analysis Date:** 2026-04-19

## Directory Layout

```text
kubebar/
├── AGENTS.md                    # Repo-wide product, architecture, coding, and quality rules
├── README.md                    # User/developer overview and build instructions
├── CONTRIBUTING.md              # Contribution and review expectations
├── CHANGELOG.md                 # Release history
├── Package.swift                # Swift Package Manager targets for app, core, and tests
├── project.yml                  # XcodeGen source for the macOS app project
├── codecov.yml                  # Coverage service configuration
├── .env.example                 # Example environment configuration, not loaded by app code
├── .github/workflows/           # GitHub Actions CI
├── .github/scripts/             # GitHub helper scripts
├── .githooks/                   # Repository git hooks
├── docs/
│   ├── architecture/            # Authoritative architecture notes
│   ├── brainstorms/             # Requirements and discovery notes
│   └── plans/                   # Roadmap and implementation plans
├── Kubebar/                     # SwiftUI macOS menu bar app target
│   ├── KubebarApp.swift         # App entry point and menu bar scene
│   ├── MenuBarViewModel.swift   # Main-actor UI state and service bridge
│   └── Views/                   # SwiftUI menu and setup views
├── KubebarCore/                 # Core model and service target
│   ├── Models/                  # App-owned value models and display contracts
│   └── Services/                # Persistence, kubectl, refresh, and health logic
├── KubebarTests/                # Swift Testing unit tests for KubebarCore
│   ├── Models/                  # Model and display behavior tests
│   └── Services/                # Service and boundary tests
├── scripts/                     # Local development and quality gate scripts
├── skills/                      # Repo-local agent workflow skills
└── tests/                       # Shell test support area
```

## Directory Purposes

**`Kubebar/`:**
- Purpose: Own the macOS app target and all SwiftUI-facing code.
- Contains: `Kubebar/KubebarApp.swift`, `Kubebar/MenuBarViewModel.swift`, and view files under `Kubebar/Views/`.
- Key files: `Kubebar/KubebarApp.swift`, `Kubebar/MenuBarViewModel.swift`, `Kubebar/Views/MenuBarRootView.swift`, `Kubebar/Views/SetupView.swift`, `Kubebar/Views/WatchlistPickerView.swift`.
- Add only app shell, view model, and presentation code here. Keep domain behavior in `KubebarCore/`.

**`Kubebar/Views/`:**
- Purpose: Render the menu bar window and setup flow from core display/setup models.
- Contains: Small `View` structs and private helper views.
- Key files: `Kubebar/Views/MenuBarRootView.swift`, `Kubebar/Views/StatusSummaryView.swift`, `Kubebar/Views/StaleBannerView.swift`, `Kubebar/Views/CompactCountersView.swift`, `Kubebar/Views/WatchlistSectionView.swift`, `Kubebar/Views/TrackedItemDetailView.swift`, `Kubebar/Views/WarningEventsView.swift`, `Kubebar/Views/NodeDetailsView.swift`, `Kubebar/Views/SetupView.swift`, `Kubebar/Views/WatchlistPickerView.swift`.
- Add new menu sections as separate SwiftUI view files in this directory when they render `MenuDisplayModel` fields or setup bindings.

**`KubebarCore/`:**
- Purpose: Own product rules, data models, persistence, external reads, and refresh coordination.
- Contains: `KubebarCore/Models/` and `KubebarCore/Services/`.
- Key files: `KubebarCore/Models/MenuDisplayModel.swift`, `KubebarCore/Services/HealthEvaluator.swift`, `KubebarCore/Services/RefreshCoordinator.swift`, `KubebarCore/Services/KubectlClusterReader.swift`.
- Keep this target independent of SwiftUI and AppKit. It should remain testable through `KubebarTests/`.

**`KubebarCore/Models/`:**
- Purpose: Define shared value types used by services, the view model, views, and tests.
- Contains: Core state, display contracts, snapshots, setup state, and watch target types.
- Key files: `KubebarCore/Models/ClusterHealthState.swift`, `KubebarCore/Models/ClusterSnapshot.swift`, `KubebarCore/Models/MenuDisplayModel.swift`, `KubebarCore/Models/MenuBarStatusPresentation.swift`, `KubebarCore/Models/SetupFlowState.swift`, `KubebarCore/Models/WatchTarget.swift`, `KubebarCore/Models/WatchlistSelectionState.swift`.
- Add new durable data shapes here when they are part of the app's product language or service contracts.

**`KubebarCore/Services/`:**
- Purpose: Implement behavior around config, subprocesses, Kubernetes reads, health evaluation, and refresh orchestration.
- Contains: Focused service structs, protocols for injection, typed errors, and private decoding helpers.
- Key files: `KubebarCore/Services/AppConfigStore.swift`, `KubebarCore/Services/CommandRunner.swift`, `KubebarCore/Services/ContextCatalog.swift`, `KubebarCore/Services/HealthEvaluator.swift`, `KubebarCore/Services/KubectlClusterReader.swift`, `KubebarCore/Services/RefreshCoordinator.swift`.
- Add new services here when they perform behavior that should be unit tested or shared by app/UI callers.

**`KubebarTests/`:**
- Purpose: Test trusted behavior in the core target.
- Contains: Swift Testing suites split by models and services.
- Key files: `KubebarTests/Models/MenuDisplayModelTests.swift`, `KubebarTests/Services/KubectlClusterReaderTests.swift`, `KubebarTests/Services/RefreshCoordinatorTests.swift`, `KubebarTests/Services/AppConfigStoreTests.swift`.
- Add tests matching the source folder: model tests in `KubebarTests/Models/`, service tests in `KubebarTests/Services/`.

**`docs/`:**
- Purpose: Hold requirements, plans, roadmap, and architecture notes.
- Contains: `docs/architecture/`, `docs/brainstorms/`, and `docs/plans/`.
- Key files: `docs/architecture/README.md`, `docs/architecture/system-overview.md`, `docs/architecture/runtime-invariants.md`, `docs/plans/2026-04-19-002-kubebar-product-roadmap.md`.
- Update `docs/architecture/` when ownership boundaries, data flow, runtime invariants, or subsystem behavior changes.

**`scripts/`:**
- Purpose: Provide local setup and verification commands.
- Contains: `scripts/swift-quality-gate.sh`, `scripts/dev-setup.sh`, and `scripts/check_no_panics.py`.
- Key files: `scripts/swift-quality-gate.sh`.
- Keep verification scripts here and reference them from `AGENTS.md`, `README.md`, and CI when behavior changes.

**`.github/`:**
- Purpose: Run repository automation in GitHub.
- Contains: `.github/workflows/ci.yml` and helper scripts under `.github/scripts/`.
- Key files: `.github/workflows/ci.yml`.
- CI calls `./scripts/swift-quality-gate.sh ci`; keep CI behavior aligned with the local gate.

**`skills/`:**
- Purpose: Store repo-local agent workflow instructions for GitHub, review, plan, triage, and ship tasks.
- Contains: `skills/github/SKILL.md`, `skills/review-pr/SKILL.md`, `skills/ship/SKILL.md`, `skills/triage-prs/SKILL.md`, `skills/plan-mode/SKILL.md`, and related workflow skills.
- Key files: `skills/ship/SKILL.md`, `skills/review-pr/SKILL.md`, `skills/github/SKILL.md`.
- These files guide contributor/agent workflows and are not part of the app runtime.

**`tests/`:**
- Purpose: Shell-level test support.
- Contains: `tests/swift_template_support.sh`.
- Key files: `tests/swift_template_support.sh`.
- Keep Swift unit tests in `KubebarTests/`; use this area for shell helpers only.

**`.planning/`:**
- Purpose: GSD planning and codebase intelligence artifacts.
- Contains: `.planning/codebase/ARCHITECTURE.md` and `.planning/codebase/STRUCTURE.md` from this mapping pass, plus files written by other mapper agents.
- Key files: `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/STRUCTURE.md`.
- Generated: Yes
- Committed: Project-dependent

## Key File Locations

**Entry Points:**
- `Kubebar/KubebarApp.swift`: macOS app entry point, accessory activation policy, menu bar scene, root view wiring, and menu bar label.
- `Kubebar/Views/MenuBarRootView.swift`: UI composition root for setup and menu content.
- `Kubebar/MenuBarViewModel.swift`: app-level state owner and bridge from UI actions to core services.
- `KubebarCore/Services/RefreshCoordinator.swift`: core refresh entry point used by the view model.
- `scripts/swift-quality-gate.sh`: local and CI quality-gate entry point.

**Configuration:**
- `Package.swift`: Swift Package Manager manifest with `Kubebar`, `KubebarCore`, and `KubebarCoreTests` targets.
- `project.yml`: XcodeGen manifest with macOS app, framework, and unit-test targets.
- `Kubebar.xcodeproj/project.pbxproj`: generated Xcode project committed in the repo.
- `Kubebar.xcodeproj/xcshareddata/xcschemes/Kubebar.xcscheme`: shared Xcode scheme used by the quality gate.
- `.github/workflows/ci.yml`: GitHub Actions workflow that runs the Swift quality gate.
- `codecov.yml`: coverage reporting configuration.
- `.env.example`: example environment configuration. Do not read real `.env` files.

**Core Logic:**
- `KubebarCore/Services/HealthEvaluator.swift`: severity, attention ordering, display mapping, watchlist cap, and stale banner logic.
- `KubebarCore/Services/RefreshCoordinator.swift`: config validation, reader coordination, failure handling, and stale snapshot retention.
- `KubebarCore/Services/KubectlClusterReader.swift`: Kubernetes JSON reads, decoding, and tracked item status calculation.
- `KubebarCore/Services/CommandRunner.swift`: subprocess execution boundary.
- `KubebarCore/Services/AppConfigStore.swift`: persisted selected context and watchlist.
- `KubebarCore/Services/ContextCatalog.swift`: available Kubernetes context listing.
- `KubebarCore/Models/MenuDisplayModel.swift`: single render contract for menu UI.
- `KubebarCore/Models/ClusterSnapshot.swift`: app-owned cluster snapshot shape.
- `KubebarCore/Models/WatchTarget.swift`: watchlist target and tracked item status shape.

**UI:**
- `Kubebar/KubebarApp.swift`: menu bar shell and status icon mapping.
- `Kubebar/MenuBarViewModel.swift`: published UI state and setup/refresh actions.
- `Kubebar/Views/MenuBarRootView.swift`: menu layout.
- `Kubebar/Views/SetupView.swift`: setup screen and finish action.
- `Kubebar/Views/WatchlistPickerView.swift`: namespace/workload watchlist selection UI.
- `Kubebar/Views/StatusSummaryView.swift`: context, health sentence, and state label.
- `Kubebar/Views/StaleBannerView.swift`: stale-data warning.
- `Kubebar/Views/WatchlistSectionView.swift`: first-screen watchlist rows and overflow count.

**Testing:**
- `KubebarTests/Models/MenuDisplayModelTests.swift`: health display behavior and stale display expectations.
- `KubebarTests/Models/ClusterHealthStateTests.swift`: health state labels.
- `KubebarTests/Models/MenuBarStatusPresentationTests.swift`: menu bar icon/accessibility presentation.
- `KubebarTests/Models/SetupFlowStateTests.swift`: setup validation and copy.
- `KubebarTests/Models/WatchlistSelectionStateTests.swift`: watchlist selection behavior.
- `KubebarTests/Services/KubectlClusterReaderTests.swift`: kubectl JSON decoding, error mapping, and concurrent resource reads.
- `KubebarTests/Services/RefreshCoordinatorTests.swift`: refresh success, stale fallback, and missing setup behavior.
- `KubebarTests/Services/AppConfigStoreTests.swift`: config load/save/corrupt cases.
- `KubebarTests/Services/CommandRunnerTests.swift`: process command boundary behavior.
- `KubebarTests/Services/ContextCatalogTests.swift`: context listing and failure behavior.

**Documentation:**
- `AGENTS.md`: highest-priority repo-wide contributor/agent contract.
- `README.md`: project overview, current status, build/test instructions, and project layout.
- `docs/architecture/system-overview.md`: major subsystems and request flow.
- `docs/architecture/runtime-invariants.md`: runtime guarantees for product, data, freshness, watchlist, and failures.
- `docs/architecture/README.md`: architecture notes index.
- `docs/plans/2026-04-19-002-kubebar-product-roadmap.md`: roadmap entry point.

## Naming Conventions

**Files:**
- Use PascalCase Swift type names as filenames for app and core files: `KubebarCore/Services/HealthEvaluator.swift`, `KubebarCore/Models/MenuDisplayModel.swift`, `Kubebar/Views/SetupView.swift`.
- Use `*View.swift` for SwiftUI views: `Kubebar/Views/StatusSummaryView.swift`, `Kubebar/Views/WatchlistPickerView.swift`.
- Use `*Tests.swift` for Swift Testing suites: `KubebarTests/Services/RefreshCoordinatorTests.swift`.
- Use lowercase hyphenated names for shell scripts and docs where already established: `scripts/swift-quality-gate.sh`, `docs/architecture/system-overview.md`.
- Use uppercase root or generated GSD reference docs where established: `AGENTS.md`, `README.md`, `.planning/codebase/ARCHITECTURE.md`.

**Directories:**
- Use target-aligned PascalCase directories for Swift targets: `Kubebar/`, `KubebarCore/`, `KubebarTests/`.
- Use domain subdirectories inside targets: `KubebarCore/Models/`, `KubebarCore/Services/`, `Kubebar/Views/`.
- Use lowercase directories for docs, scripts, tests, and skills: `docs/`, `scripts/`, `tests/`, `skills/`.

## Where to Add New Code

**New Menu Section:**
- Primary code: `Kubebar/Views/`
- Data contract: `KubebarCore/Models/MenuDisplayModel.swift`
- Mapping logic: `KubebarCore/Services/HealthEvaluator.swift`
- Tests: `KubebarTests/Models/MenuDisplayModelTests.swift`
- Add the view to `Kubebar/Views/MenuBarRootView.swift` only after the display model exposes the needed field.

**New Health Rule:**
- Primary code: `KubebarCore/Services/HealthEvaluator.swift`
- Supporting model: `KubebarCore/Models/ClusterHealthState.swift` only if the categorical state set changes.
- Tests: `KubebarTests/Models/MenuDisplayModelTests.swift`
- Keep severity decisions centralized in `HealthEvaluator`.

**New Kubernetes Read:**
- Primary code: `KubebarCore/Services/KubectlClusterReader.swift`
- External boundary: `KubebarCore/Services/CommandRunner.swift`
- Snapshot/model changes: `KubebarCore/Models/ClusterSnapshot.swift` or a new model under `KubebarCore/Models/`.
- Tests: `KubebarTests/Services/KubectlClusterReaderTests.swift`
- Use the saved context argument pattern from `KubebarCore/Services/KubectlClusterReader.swift`.

**New External Command Consumer:**
- Primary code: `KubebarCore/Services/`
- Shared subprocess boundary: `KubebarCore/Services/CommandRunner.swift`
- Tests: `KubebarTests/Services/`
- Depend on `CommandRunning` rather than constructing `Process` directly.

**New Config Field:**
- Primary code: `KubebarCore/Services/AppConfigStore.swift`
- UI setup state: `KubebarCore/Models/SetupFlowState.swift` if the field is user-configurable.
- View model wiring: `Kubebar/MenuBarViewModel.swift`
- Tests: `KubebarTests/Services/AppConfigStoreTests.swift` and setup/model tests under `KubebarTests/Models/`.
- Preserve missing and corrupt config recovery behavior.

**New Setup Flow UI:**
- Primary code: `Kubebar/Views/SetupView.swift` or a new view under `Kubebar/Views/`.
- State model: `KubebarCore/Models/SetupFlowState.swift` or `KubebarCore/Models/WatchlistSelectionState.swift`.
- Persistence: `KubebarCore/Services/AppConfigStore.swift`.
- Tests: `KubebarTests/Models/SetupFlowStateTests.swift` or `KubebarTests/Models/WatchlistSelectionStateTests.swift`.

**New Core Model:**
- Implementation: `KubebarCore/Models/`
- Tests: `KubebarTests/Models/`
- Use a value type (`struct` or `enum`) and explicit public initializers when the app target needs access.

**New Core Service:**
- Implementation: `KubebarCore/Services/`
- Tests: `KubebarTests/Services/`
- Prefer initializer injection for dependencies and protocol boundaries for external reads.

**New Architecture Note:**
- Implementation: `docs/architecture/`
- Index update: `docs/architecture/README.md`
- Use this for details that are too long for `AGENTS.md`.

**New Quality Script:**
- Implementation: `scripts/`
- Documentation: `AGENTS.md` and `README.md` if it changes the standard developer workflow.
- CI wiring: `.github/workflows/ci.yml` if it should run in pull requests.

**Utilities:**
- Shared helpers for core behavior: `KubebarCore/Services/` or `KubebarCore/Models/`, depending on whether the helper performs behavior or represents data.
- UI-only helpers: private nested types or private helper views in `Kubebar/Views/`.
- Test-only helpers: private types inside the relevant `KubebarTests/` file unless multiple test files need the same helper.

## Special Directories

**`docs/architecture/`:**
- Purpose: Authoritative architecture notes beyond the repo quick-start guide.
- Generated: No
- Committed: Yes
- Key files: `docs/architecture/system-overview.md`, `docs/architecture/runtime-invariants.md`, `docs/architecture/README.md`.

**`Kubebar.xcodeproj/`:**
- Purpose: Xcode project used for app build/test and shared scheme discovery.
- Generated: Yes, from `project.yml` through XcodeGen.
- Committed: Yes
- Key files: `Kubebar.xcodeproj/project.pbxproj`, `Kubebar.xcodeproj/xcshareddata/xcschemes/Kubebar.xcscheme`.

**`.github/workflows/`:**
- Purpose: Pull request CI.
- Generated: No
- Committed: Yes
- Key files: `.github/workflows/ci.yml`.

**`skills/`:**
- Purpose: Repo-local agent workflow definitions for GitHub and project operations.
- Generated: No
- Committed: Yes
- Key files: `skills/github/SKILL.md`, `skills/review-pr/SKILL.md`, `skills/ship/SKILL.md`, `skills/plan-mode/SKILL.md`.

**`.planning/codebase/`:**
- Purpose: Generated GSD codebase map consumed by planning and execution commands.
- Generated: Yes
- Committed: Project-dependent
- Key files: `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/STRUCTURE.md`.

**`scripts/__pycache__/`:**
- Purpose: Python bytecode cache from script execution.
- Generated: Yes
- Committed: No
- Key files: `scripts/__pycache__/check_no_panics.cpython-314.pyc`.

---

*Structure analysis: 2026-04-19*
