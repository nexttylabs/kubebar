# External Integrations

**Analysis Date:** 2026-04-19

## APIs & External Services

**Kubernetes:**
- Kubernetes clusters are read through the local `kubectl` executable, not through an embedded Kubernetes SDK.
  - SDK/Client: `kubectl` invoked by `KubebarCore/Services/CommandRunner.swift`.
  - Auth: delegated to the user's existing `kubectl` and kubeconfig setup; no app-owned credential store is present.
  - Context discovery: `KubebarCore/Services/ContextCatalog.swift` runs `kubectl config get-contexts -o name`.
  - Node health: `KubebarCore/Services/KubectlClusterReader.swift` runs `kubectl --context <context> get nodes -o json`.
  - Pod health: `KubebarCore/Services/KubectlClusterReader.swift` runs `kubectl --context <context> get pods --all-namespaces -o json`.
  - Warning events: `KubebarCore/Services/KubectlClusterReader.swift` runs `kubectl --context <context> get events --all-namespaces --field-selector type=Warning -o json`.
  - Output contract: JSON decoded with `JSONDecoder` inside `KubebarCore/Services/KubectlClusterReader.swift`.

**GitHub:**
- GitHub Actions runs pull request checks and PR labeling.
  - SDK/Client: GitHub Actions workflows in `.github/workflows/ci.yml`, `.github/workflows/pr-labels.yml`, and `.github/workflows/regression-test-check.yml`.
  - Auth: `secrets.GITHUB_TOKEN` is used by `.github/workflows/pr-labels.yml`.
- GitHub API is used by repository helper scripts.
  - SDK/Client: `gh` CLI in `.github/scripts/pr-labeler.sh` and `.github/scripts/create-labels.sh`.
  - Auth: `GH_TOKEN` in `.github/workflows/pr-labels.yml` for CI; local `gh` authentication for manual script use.
  - Repository input: `REPO` and `PR_NUMBER` environment variables in `.github/scripts/pr-labeler.sh`; `REPO` in `.github/scripts/create-labels.sh`.
- GitHub labeler action applies scope labels.
  - SDK/Client: `actions/labeler@v5` in `.github/workflows/pr-labels.yml`.
  - Auth: `secrets.GITHUB_TOKEN`.
  - Rules: `.github/labeler.yml`.

**Coverage Services:**
- Codecov thresholds are configured but upload wiring is not detected.
  - SDK/Client: `codecov.yml` only.
  - Auth: Not detected.

## Data Storage

**Databases:**
- None detected. No Core Data, SQLite, database client, ORM, or hosted database integration is present in `Kubebar/`, `KubebarCore/`, `Package.swift`, or `project.yml`.

**File Storage:**
- Local filesystem only.
  - Config file: `Application Support/Kubebar/config.json`.
  - Implementation: `KubebarCore/Services/AppConfigStore.swift`.
  - Directory selection: `Kubebar/MenuBarViewModel.swift`.
  - Stored fields: selected Kubernetes context, watch targets, and refresh interval from `AppConfig`.
- Test-only temporary files are created in `KubebarTests/Services/AppConfigStoreTests.swift`.

**Caching:**
- External cache: None.
- In-memory state: `Kubebar/MenuBarViewModel.swift` keeps the latest `ClusterSnapshot?`; `KubebarCore/Services/RefreshCoordinator.swift` uses the previous snapshot when refresh fails so stale data is clearly marked.

## Authentication & Identity

**Auth Provider:**
- No app-level user authentication provider is present.
  - Implementation: The app is a local macOS utility and does not create accounts or sessions.
  - Kubernetes identity: delegated to `kubectl`; Kubebar stores the selected context name, not credentials.
  - GitHub identity: delegated to GitHub Actions `GITHUB_TOKEN` and local `gh` authentication for repository scripts.

## Monitoring & Observability

**Error Tracking:**
- None detected. No Sentry, Crashlytics, OpenTelemetry, Datadog, or custom remote error reporting package is present.

**Logs:**
- App runtime logging framework: Not detected.
- User-visible failure path: `KubebarCore/Services/RefreshCoordinator.swift` converts reader failures into `RefreshFailure`; `KubebarCore/Services/HealthEvaluator.swift` renders stale display state and failure reasons.
- CI logs: GitHub Actions logs from `.github/workflows/ci.yml`, `.github/workflows/pr-labels.yml`, and `.github/workflows/regression-test-check.yml`.
- Coverage status configuration: `codecov.yml`.

## CI/CD & Deployment

**Hosting:**
- Not applicable for the app. Kubebar is a native macOS app with no hosted runtime.

**CI Pipeline:**
- Pull request quality gate: `.github/workflows/ci.yml` runs `./scripts/swift-quality-gate.sh ci` on `macos-latest`.
- Pull request labels: `.github/workflows/pr-labels.yml` runs `actions/labeler@v5` and `.github/scripts/pr-labeler.sh`.
- Regression test enforcement: `.github/workflows/regression-test-check.yml` requires test changes for fix-style PRs unless `skip-regression-check` is present.
- Local pre-push gate: `.githooks/pre-push` runs `./scripts/swift-quality-gate.sh local`.
- Distribution or release deployment automation: Not detected.

## Environment Configuration

**Required env vars:**
- App runtime: None read directly by Swift source.
- Kubernetes access: `kubectl` must be installed and configured for the selected context. Standard `kubectl` configuration may come from the user's kubeconfig or environment, but Kubebar does not read kubeconfig values itself.
- Quality gate overrides: `XCODE_WORKSPACE`, `XCODE_PROJECT`, `XCODE_SCHEME`, `XCODE_CONFIGURATION`, `XCODE_DESTINATION`, and `XCODE_DERIVED_DATA_PATH` are supported by `scripts/swift-quality-gate.sh`.
- GitHub Actions CI variables: `.github/workflows/ci.yml` passes repository variables named `XCODE_WORKSPACE`, `XCODE_PROJECT`, `XCODE_SCHEME`, `XCODE_CONFIGURATION`, and `XCODE_DESTINATION`.
- PR label script: `.github/scripts/pr-labeler.sh` requires `PR_NUMBER` and `REPO`; `.github/workflows/pr-labels.yml` also provides `GH_TOKEN`.
- Label creation script: `.github/scripts/create-labels.sh` requires `REPO`.

**Secrets location:**
- GitHub workflow token: `secrets.GITHUB_TOKEN` in `.github/workflows/pr-labels.yml`.
- Local app secrets: None detected.
- Environment files: `.env.example` exists but its contents were not read. `.gitignore` excludes `.env` and `.env.local`.
- Kubernetes credentials: managed outside Kubebar by the user's `kubectl`/kubeconfig setup.

## Webhooks & Callbacks

**Incoming:**
- App runtime: None.
- Repository automation: GitHub pull request events trigger `.github/workflows/ci.yml`, `.github/workflows/pr-labels.yml`, and `.github/workflows/regression-test-check.yml`.

**Outgoing:**
- App runtime: No direct HTTP client is present. Kubernetes communication happens indirectly through `kubectl` subprocess calls from `KubebarCore/Services/KubectlClusterReader.swift` and `KubebarCore/Services/ContextCatalog.swift`.
- Repository automation: `.github/scripts/pr-labeler.sh` and `.github/scripts/create-labels.sh` call GitHub through `gh`.

---

*Integration audit: 2026-04-19*
