# Kubebar Context

## Canonical Terms

- **Kubebar**: a native macOS menu bar app for glanceable Kubernetes health.
- **Health category**: one of `OK`, `Watch`, `Bad`, or `Stale`; only
  `HealthEvaluator` decides it.
- **Resource usage visualization**: lightweight current-snapshot CPU and memory
  indicators, such as inline progress bars, derived from existing app-owned
  metrics data.
- **Progress value**: an optional `Double` display-model value where `nil`
  means unavailable and numeric values are clamped by the view for rendering.
- **Unavailable resource data**: missing or invalid CPU or memory usage or
  comparison basis; it is shown as unavailable, never as healthy zero.
- **Start at Login setting**: a macOS app setting that controls whether
  Kubebar opens automatically after the user logs in. It is local app behavior,
  not Kubernetes configuration, and it must not affect Health category.
- **Health State Shift Alerts**: optional macOS notifications for true
  directionally worse Health category or watchlist attention changes. They are
  local app behavior, consume `MenuDisplayModel`, and must not add new health
  rules.
- **AI Diagnostic Assistant**: an optional app-wide feature for manually testing
  a configured AI provider and, from explicit troubleshooting surfaces,
  explaining user-approved Kubernetes diagnostic context. It is display/help
  behavior only and must not change `Health category`.
- **AI Provider configuration**: non-secret app-wide provider metadata such as
  provider kind, `Model ID`, an `OpenAI-compatible` `Base URL`, and custom AI
  diagnostic prompt instructions. It belongs in App Settings and may be
  persisted in local app config.
- **AI diagnostic prompt instructions**: optional user-authored Pod/Event
  diagnosis instructions edited in `AI Assistant` Settings. They start from
  built-in defaults, reset by clearing the custom override, and cannot replace
  Kubebar's fixed safety prompt or code-owned diagnostic context payload.
- **AI Provider API key**: the secret credential for an AI provider. It must be
  stored in macOS Keychain, never in `AppConfig`, command output, diagnostics,
  or visible raw error text.
- **OpenAI-compatible provider**: a custom endpoint that uses only `Bearer` API
  key authentication, `Base URL`, and `Model ID` in the first version. Custom
  headers are out of scope.
- **AI Pod diagnostic input**: a manually submitted AI diagnostic payload from
  the Pod Micro-Logs Drawer. It is limited to the selected Pod's display-ready
  status, up to 3 related warning summaries, and a freshly read, bounded,
  redacted `kubectl logs --tail=50` sample. It does not include Kubernetes
  Secrets, kubeconfig content, raw cluster JSON, full command transcripts, or
  automatically executed remediation.
- **AI Event diagnostic input**: a manually submitted AI diagnostic payload from
  `Overview` `Recent Warnings`. It is limited to a fresh `kubectl get events`
  read through Kubebar's app-owned context, exact matching by `namespace`,
  `objectKind`, `objectName`, and `reason`, and the latest 5 matching redacted
  Warning Events. It does not include Pod logs, Kubernetes Secrets, kubeconfig
  content, raw cluster JSON, full command transcripts, or automatically
  executed remediation.
- **Pod Micro-Logs Drawer**: a user-opened focusable log window for a single
  `Bad` Pod row that streams a bounded `kubectl logs --tail=100 -f` view
  through Kubebar's app-owned context and kubeconfig. It is temporary
  troubleshooting UI, not stored history, alerting, or a Health category input.
- **Read-only log text view**: the native macOS text surface used inside the
  Pod Micro-Logs Drawer for log output. It should use AppKit text behavior for
  top-left log layout, selection, copy, and scrolling instead of rebuilding a
  text viewer from primitive SwiftUI `ScrollView` and `Text`.
- **App Settings page**: one of the fixed App-level Settings pages in the
  Settings sidebar: `General`, `Kubernetes`, `Notifications`, and `AI Assistant`.
  They are app-wide behavior such as refresh cadence, Start at Login, Health
  State Shift Alerts, explicit kubeconfig paths, and AI Diagnostic Assistant
  configuration, and are not tied to a Kubernetes context.
- **Context Settings page**: a Settings page generated from local context
  information. It edits the per-context watchlist for exactly one Kubernetes
  context.
- **Per-context watchlist**: a saved set of watch targets keyed by Kubernetes
  context name. Kubebar still has one active selected context at a time, but
  each context may keep its own watchlist for refreshes and Settings editing.
- **Quick Context Selector**: the menu-surface submenu that switches Kubebar's
  active app-owned selected context. It must list local context information,
  use the active context's per-context watchlist, and must not change the
  terminal's current context.
- **KUBECONFIG environment**: the inherited `KUBECONFIG` process environment
  value used by `kubectl` to resolve local kubeconfig files. On Linux/macOS,
  multiple files are separated with `:` and Kubebar delegates merging to
  `kubectl`.
- **Explicit kubeconfig paths**: an ordered App Settings list of kubeconfig
  files owned by Kubebar. When the list is empty, Kubebar falls back to
  automatic `KUBECONFIG` detection; when it has entries, Kubebar uses those
  paths to build the `KUBECONFIG` value for `kubectl`.
- **Release build version**: the app bundle build number (`CFBundleVersion` /
  `CURRENT_PROJECT_VERSION`) used for release artifacts. It must move in sync
  with release publishing and stay distinct from the user-facing marketing
  version (`CFBundleShortVersionString` / `MARKETING_VERSION`).

## Vocabulary Guard

In this repository, "chart" for resource usage means lightweight current-state
visualization inside the menu. It does not mean historical trends, sparklines,
time-series storage, or an external monitoring dashboard unless a future plan
explicitly changes that scope.

## Architecture Map

- Release tooling: `scripts/build-release.sh` owns packaged app version
  metadata, `scripts/test-release-build-version.sh` guards release metadata
  regressions, `project.yml` provides XcodeGen defaults, and
  `docs/RELEASING.md` documents release-owner behavior.
- Context and Settings state: `KubebarCore/Services/AppConfigStore.swift` owns
  saved active context and per-context watchlists,
  `KubebarCore/Models/SetupFlowState.swift` and
  `KubebarCore/Models/MenuRuntimeState.swift` model Settings/menu state,
  `Kubebar/MenuBarViewModel.swift` wires local context loading and active
  context switching, and
  `docs/solutions/architecture/per-context-watchlists-active-context-2026-06-03.md`
  captures the reusable ownership pattern.
- Kubernetes command environment: `KubebarCore/Services/CommandRunner.swift`
  owns inherited process environment and PATH normalization for launched tools,
  while `KubebarCore/Services/ContextCatalog.swift`,
  `KubebarCore/Services/WatchTargetCatalog.swift`, and
  `KubebarCore/Services/KubectlClusterReader.swift` own `kubectl` reads.
- Explicit kubeconfig paths: `KubebarCore/Services/AppConfigStore.swift` owns
  persistence, `KubebarCore/Models/SetupFlowState.swift` and
  `KubebarCore/Models/MenuRuntimeState.swift` own Settings editing state, and
  `Kubebar/Views/SetupView.swift`, `Kubebar/Views/SettingsRootView.swift`, and
  `Kubebar/MenuBarViewModel.swift` own the App Settings UI and selected-file
  flow.
- Pod Micro-Logs Drawer: `KubebarCore/Models/MenuDisplayModel.swift` carries
  display-ready Pod row identity, `KubebarCore/Services/HealthEvaluator.swift`
  maps `PodDetail` into `PodItemDisplay`, `KubebarCore/Services/CommandRunner.swift`
  owns process-launch environment behavior, `KubebarCore/Services/PodDiagnosticLogReader.swift`
  owns finite AI diagnostic log reads, `KubebarCore/Services/AIPodDiagnosticRequester.swift`
  owns provider diagnostic requests, `Kubebar/MenuBarViewModel.swift` owns
  app-owned context and lifecycle cancellation, and `Kubebar/Views/PodsTabView.swift`
  plus `Kubebar/Views/MenuBarRootView.swift` own the row entry point and
  focusable log window UI. The log body should be hosted by a Read-only log
  text view rather than a hand-built text scroller.
- AI Event diagnostics: `KubebarCore/Models/MenuDisplayModel.swift` carries an
  explicit `WarningEventDiagnosticTarget` for structured warning groups,
  `KubebarCore/Services/HealthEvaluator.swift` derives that target from Warning
  Event records, `KubebarCore/Services/WarningEventDiagnosticReader.swift` owns
  fresh latest-5 event reads, `KubebarCore/Services/AIEventDiagnosticRequester.swift`
  owns provider diagnostic requests, `Kubebar/MenuBarViewModel.swift` owns
  transient diagnosis lifecycle, and `Kubebar/Views/OverviewTabView.swift` owns
  the `Overview` `Recent Warnings` entry point. `Kubebar/Views/WarningEventsView.swift`
  remains a shared row renderer and must not infer diagnostic targets in the
  Events tab.
- AI diagnostic prompt customization: `KubebarCore/Models/AIDiagnosticAssistantConfig.swift`
  owns non-secret Pod/Event prompt overrides plus built-in defaults,
  `KubebarCore/Models/SetupFlowState.swift` owns Settings mutations/reset,
  `Kubebar/Views/SetupView.swift` owns the editors, and the Pod/Event
  diagnostic requesters combine effective prompt instructions with code-owned
  safety prompts and bounded diagnostic context.
