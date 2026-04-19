# Technology Stack

**Analysis Date:** 2026-04-19

## Languages

**Primary:**
- Swift 6.0 - Product app, reusable core module, and unit tests. Declared by `Package.swift` and `project.yml`; source lives in `Kubebar/`, `KubebarCore/`, and `KubebarTests/`.

**Secondary:**
- Bash - Local setup, quality gates, Git hooks, and GitHub helper scripts in `scripts/swift-quality-gate.sh`, `scripts/dev-setup.sh`, `.githooks/pre-push`, `.githooks/commit-msg`, `.github/scripts/pr-labeler.sh`, and `.github/scripts/create-labels.sh`.
- YAML - XcodeGen, CI, labeler, and coverage configuration in `project.yml`, `.github/workflows/ci.yml`, `.github/workflows/pr-labels.yml`, `.github/workflows/regression-test-check.yml`, `.github/labeler.yml`, and `codecov.yml`.
- Python 3 - Auxiliary repository script in `scripts/check_no_panics.py`; it is not part of the Swift app runtime.

## Runtime

**Environment:**
- Native macOS menu bar utility targeting macOS 14.0 or newer.
- `Kubebar/KubebarApp.swift` uses `SwiftUI.MenuBarExtra` with `.menuBarExtraStyle(.window)`.
- `Kubebar/KubebarApp.swift` imports `AppKit` and sets `NSApplication` activation policy to `.accessory`.
- `project.yml` sets `INFOPLIST_KEY_LSUIElement: YES`, so the app runs as a menu bar accessory instead of a regular Dock app.

**Package Manager:**
- Swift Package Manager, declared by `Package.swift`.
- Lockfile: missing. No `Package.resolved` is present because no external Swift package dependencies are declared.
- Additional project generator: XcodeGen through `project.yml`; `README.md` documents `xcodegen generate` after target or source folder changes. The XcodeGen version is not pinned in the repository.

## Frameworks

**Core:**
- SwiftUI - Menu bar scene, views, setup UI, watchlist UI, and display rendering in `Kubebar/KubebarApp.swift` and `Kubebar/Views/`.
- AppKit - macOS application activation policy in `Kubebar/KubebarApp.swift`.
- Foundation - Processes, files, JSON decoding, dates, locks, and concurrency helpers in `KubebarCore/Services/` and `KubebarCore/Models/`.
- Swift Concurrency - UI-to-background refresh flow uses `Task` and `Task.detached` in `Kubebar/MenuBarViewModel.swift`; subprocess fan-out uses `DispatchGroup` and `DispatchQueue` in `KubebarCore/Services/KubectlClusterReader.swift`.

**Testing:**
- Swift Testing - Test files import `Testing` and use `@Suite`, `@Test`, and `#expect` in `KubebarTests/Services/` and `KubebarTests/Models/`.
- Xcode test runner - `scripts/swift-quality-gate.sh` runs `xcodebuild ... test` against the shared `Kubebar` scheme in `Kubebar.xcodeproj/xcshareddata/xcschemes/Kubebar.xcscheme`.
- SwiftPM test runner - `scripts/swift-quality-gate.sh` runs `swift test` when `Package.swift` is present.

**Build/Dev:**
- Xcode project - `Kubebar.xcodeproj/` contains the committed macOS app project and shared scheme.
- XcodeGen - `project.yml` is the source for regenerating `Kubebar.xcodeproj/`.
- SwiftPM - `Package.swift` defines executable product `Kubebar`, library product `KubebarCore`, and test target `KubebarCoreTests`.
- Quality gate - `scripts/swift-quality-gate.sh local` runs Xcode build, Xcode tests, `swift build`, and `swift test`.
- Git hooks - `.githooks/pre-push` runs the Swift quality gate; `.githooks/commit-msg` enforces tests for fix commits.
- GitHub Actions - `.github/workflows/ci.yml`, `.github/workflows/pr-labels.yml`, and `.github/workflows/regression-test-check.yml` run pull request checks and labels.

## Key Dependencies

**Critical:**
- Apple SDK frameworks - `SwiftUI`, `AppKit`, and `Foundation` are the only product code frameworks imported by `Kubebar/` and `KubebarCore/`.
- `kubectl` executable - Required for live Kubernetes reads. `KubebarCore/Services/ContextCatalog.swift` invokes `kubectl config get-contexts -o name`; `KubebarCore/Services/KubectlClusterReader.swift` invokes `kubectl --context <context> get ... -o json`.
- Local filesystem - Required for app configuration. `Kubebar/MenuBarViewModel.swift` selects the Application Support `Kubebar` directory, and `KubebarCore/Services/AppConfigStore.swift` reads/writes `config.json`.

**Infrastructure:**
- `xcodebuild` - Required by `scripts/swift-quality-gate.sh` and checked by `scripts/dev-setup.sh`.
- Swift toolchain - Required by `Package.swift`, `swift build`, and `swift test`; checked by `scripts/dev-setup.sh`.
- `xcodegen` - Required only when regenerating `Kubebar.xcodeproj` from `project.yml`; documented in `README.md`.
- GitHub Actions `actions/checkout@v4` - Used by `.github/workflows/ci.yml`, `.github/workflows/pr-labels.yml`, and `.github/workflows/regression-test-check.yml`.
- GitHub Actions `actions/labeler@v5` - Used by `.github/workflows/pr-labels.yml` with rules from `.github/labeler.yml`.
- GitHub CLI `gh` and `jq` - Required by `.github/scripts/pr-labeler.sh`; `gh` is also required by `.github/scripts/create-labels.sh`.
- Codecov configuration - `codecov.yml` defines project and patch coverage status thresholds. No Codecov upload workflow is detected.
- SwiftLint - Optional only. `scripts/dev-setup.sh` reports it when installed but the quality gate does not run it.

## Configuration

**Environment:**
- Runtime app configuration is stored as JSON, not environment variables. `KubebarCore/Services/AppConfigStore.swift` encodes `AppConfig` to `config.json`.
- Default app config location is `Application Support/Kubebar/config.json`, built in `Kubebar/MenuBarViewModel.swift`.
- App config contains `selectedContext`, `watchTargets`, and `refreshIntervalSeconds` from `KubebarCore/Services/AppConfigStore.swift`.
- Kubernetes credential handling is delegated to `kubectl`; the Swift app does not parse kubeconfig files, store cluster credentials, or read a `KUBECONFIG` variable directly.
- `.env.example` exists at the repository root. Its contents were not read. `.gitignore` ignores `.env` and `.env.local`.

**Build:**
- `Package.swift` sets `swift-tools-version: 6.0`, platform `.macOS(.v14)`, products, and target paths.
- `project.yml` sets `SWIFT_VERSION: "6.0"`, `MACOSX_DEPLOYMENT_TARGET: "14.0"`, bundle identifiers, target types, and the `Kubebar` scheme.
- `Kubebar.xcodeproj/xcshareddata/xcschemes/Kubebar.xcscheme` builds `Kubebar.app` and `KubebarCore.framework`, then runs `KubebarTests.xctest`.
- `scripts/swift-quality-gate.sh` accepts `XCODE_WORKSPACE`, `XCODE_PROJECT`, `XCODE_SCHEME`, `XCODE_CONFIGURATION`, `XCODE_DESTINATION`, and `XCODE_DERIVED_DATA_PATH`.
- `.github/workflows/ci.yml` passes GitHub repository variables with the same `XCODE_*` names into the quality gate.

## Platform Requirements

**Development:**
- macOS with Xcode command line tools, because `scripts/dev-setup.sh` requires `swift` and `xcodebuild`.
- Swift 6-compatible toolchain, matching `Package.swift` and `project.yml`.
- XcodeGen when changing generated Xcode project structure from `project.yml`.
- `kubectl` for running the app against real clusters and for live context discovery.
- GitHub CLI `gh` and `jq` for PR label scripts in `.github/scripts/pr-labeler.sh`.
- Optional SwiftLint only if the project adopts it; no SwiftLint config is present.

**Production:**
- macOS 14.0 or newer.
- Native app bundle identifier `com.nextty.kubebar` from `project.yml`.
- Local `kubectl` installation with access to the user-selected Kubernetes context.
- No server backend, database server, hosted API, or external Swift package dependency is required by the app.

---

*Stack analysis: 2026-04-19*
