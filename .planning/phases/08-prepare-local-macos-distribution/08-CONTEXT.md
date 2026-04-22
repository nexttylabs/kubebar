# Phase 08: Prepare Local macOS Distribution - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning
**Source issue:** https://github.com/nexttylabs/kubebar/issues/8

<domain>

## Phase Boundary

This phase makes Kubebar installable for local daily use without opening Xcode.
It turns the already verified menu bar app into a repeatable local app-bundle
install path.

This phase delivers:

- A first local distribution shape for Kubebar.
- A scriptable build/install path for a macOS `.app` bundle.
- Documentation for install, update, uninstall, and config reset.
- Verification that local quality checks pass before producing the installable
  bundle.
- Bundle-level checks that the installed app still looks and behaves like the
  Kubebar menu bar utility.

This phase does not deliver:

- Developer ID signing, notarization, or public release readiness.
- Homebrew, Sparkle, auto-update, pkg, dmg, or release automation.
- A broader QA phase; issue #7 is already closed and this phase consumes its
  readiness signal instead of recreating it.
- Changes to health evaluation, watchlist behavior, Kubernetes reads, or menu
  content.
- Any deeper-debugging handoff such as `Open in k9s`.

</domain>

<decisions>

## Implementation Decisions

### First Local Distribution Shape

- **D-01:** Use a copied macOS `.app` bundle as the first local distribution
  shape.
- **D-02:** Build the app through the Xcode project path, not the SwiftPM
  executable output, because the installable product is `Kubebar.app`.
- **D-03:** Default installation should target the user's local Applications
  directory, such as `~/Applications/Kubebar.app`, so the first installer path
  does not require admin privileges.
- **D-04:** Do not create a pkg, dmg, Homebrew formula, Sparkle feed, or release
  artifact in this phase.

### Build and Install Behavior

- **D-05:** The local install flow must run the existing quality gate before
  copying the app bundle.
- **D-06:** The installable bundle should be built with an install-oriented
  configuration, preferably `Release`, while preserving the existing `Debug`
  smoke flow for local development.
- **D-07:** The install step may quit a running Kubebar instance before replacing
  the bundle, but it must target Kubebar specifically and avoid broad process
  cleanup.
- **D-08:** Re-running the install command should act as the update path:
  rebuild, verify, replace the existing local app bundle, and leave user config
  intact.
- **D-09:** Uninstall docs should remove the copied app bundle separately from
  config reset, so users can remove the app without accidentally deleting their
  saved context and watchlist.

### Signing Boundary

- **D-10:** Do not require a Developer ID certificate or team configuration.
- **D-11:** Ad-hoc or local signing is allowed only if needed to make the copied
  local app bundle launch reliably, but it must not expand into notarization or
  public distribution.
- **D-12:** Keep `project.yml` as the source of truth for app bundle settings.
  Do not make durable packaging settings only in generated Xcode project files.

### Install Documentation

- **D-13:** README or install docs must explain local build/install/update/
  uninstall steps without requiring the user to open Xcode.
- **D-14:** Docs must name the app config location as
  `~/Library/Application Support/Kubebar/config.json` and explain that resetting
  Kubebar config does not touch kubeconfig or Kubernetes credentials.
- **D-15:** Docs should keep the privacy boundary explicit: Kubebar stores the
  selected context, watch targets, and refresh cadence; Kubernetes credentials
  remain owned by `kubectl`.
- **D-16:** Docs should keep distribution separate from app behavior. Installing
  the app must not weaken watchlist-first reading, stale-state visibility, or
  the four menu bar states.

### Verification

- **D-17:** Verify the local distribution path with `./scripts/swift-quality-gate.sh local`.
- **D-18:** Verify that the built or installed `.app` bundle exists and contains
  the expected app metadata and assets, including the app icon and asset catalog.
- **D-19:** A visible-app smoke check should remain available through
  `./scripts/compile-and-run.sh` or an equivalent local command, but this phase
  should not depend on new UI automation.
- **D-20:** Distribution verification should include the exact generated app path
  and install destination so a user can find what was produced.

### the agent's Discretion

- The planner may choose exact script names, such as `install-local.sh` or
  `package-local.sh`, as long as the first distribution shape remains a copied
  app bundle.
- The planner may decide whether install and uninstall are separate scripts or
  documented commands, as long as install, update, uninstall, and reset are all
  clear.
- The planner may choose the exact bundle metadata checks, but must include
  enough proof that the copied app is a real Kubebar menu bar app.
- The planner may decide whether the install command relaunches Kubebar by
  default or exposes relaunch as an explicit option.

</decisions>

<canonical_refs>

## Canonical References

Downstream agents MUST read these before planning or implementing.

### Product Scope

- `AGENTS.md` - repo rules, Kubebar product guardrails, and local quality gate.
- `https://github.com/nexttylabs/kubebar/issues/8` - source issue for local
  macOS distribution scope and acceptance criteria.
- `https://github.com/nexttylabs/kubebar/issues/7` - prior operator-facing QA
  gate; currently closed, so distribution may proceed without recreating QA.
- `docs/plans/2026-04-19-002-kubebar-product-roadmap.md` - lists issue #8 as
  the packaging step after the core daily-use loop is stable.
- `docs/plans/2026-04-19-001-feat-kubebar-watchlist-menu-plan.md` - original
  plan that defers distribution packaging, notarization, Homebrew, and release
  automation to separate work.
- `README.md` - current build, quality gate, and visible-app smoke instructions
  that install docs should extend.

### Architecture and Runtime Rules

- `docs/architecture/system-overview.md` - app/core/service ownership and menu
  rendering boundary.
- `docs/architecture/runtime-invariants.md` - runtime rules that distribution
  must not weaken, including four states, watchlist-first display, freshness,
  keyboard, and privacy boundaries.
- `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-CONTEXT.md`
  - locks menu bar icon, keyboard, truncation, and non-color status decisions.
- `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md`
  - records visible-app smoke evidence and remaining human-only menu checks.
- `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-VERIFICATION.md`
  - verifies Phase 06 source and automated checks, with human visual checks kept
  explicit.

### Build and Packaging Inputs

- `project.yml` - XcodeGen source of truth for the macOS app target,
  `LSUIElement`, bundle identifier, product name, and app icon setting.
- `Package.swift` - SwiftPM target shape; useful for quality gate parity but not
  the source of the installable `.app` bundle.
- `scripts/swift-quality-gate.sh` - required local quality gate before producing
  the app bundle.
- `scripts/compile-and-run.sh` - existing visible-app smoke path and current
  built app path convention.
- `.planning/codebase/STACK.md` - current Swift, Xcode, XcodeGen, and macOS
  build stack.
- `.planning/codebase/STRUCTURE.md` - app, core, docs, and script locations.
- `.planning/codebase/TESTING.md` - test framework and supported verification
  commands.
- `.planning/codebase/INTEGRATIONS.md` - no deployment automation is currently
  present; app runtime depends on local `kubectl`.
- `.planning/codebase/CONVENTIONS.md` - script, style, and error-handling
  conventions.
- `.planning/codebase/CONCERNS.md` - notes packaging-related drift risk between
  `project.yml`, `Package.swift`, and generated Xcode project output.

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- `scripts/swift-quality-gate.sh`: Already runs Xcode build, Xcode tests,
  `swift build`, and `swift test`; this remains the pre-install gate.
- `scripts/compile-and-run.sh`: Already builds, tests, locates
  `DerivedData/Build/Products/<configuration>/Kubebar.app`, quits an existing
  Kubebar process, launches the built app, and reports the app path.
- `project.yml`: Defines the installable macOS app target with bundle id
  `com.nextty.kubebar`, product name `Kubebar`, `LSUIElement`, app category, and
  `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`.
- `Kubebar/MenuBarViewModel.swift`: Defines the default config directory under
  user Application Support with a `Kubebar` child directory.
- `KubebarCore/Services/AppConfigStore.swift`: Persists `config.json` with
  selected context, watch targets, and refresh cadence.
- `README.md`: Already explains Xcode opening, `xcodegen generate`, the quality
  gate, and the visible-app smoke command; it needs local install/update/
  uninstall/reset guidance.

### Established Patterns

- `project.yml` is the durable source for app target settings; generated project
  files should not be the only place where packaging settings change.
- The local quality gate is the source of truth before handing an app bundle to
  a user.
- The app stores local operational preferences, not Kubernetes credentials.
- Distribution work must not change the menu product contract: categorical
  status icon, watchlist-first menu, stale data visibly marked stale, and no
  deep troubleshooting in V1.

### Integration Points

- A local install script should likely live under `scripts/` and reuse the
  existing build variables from `scripts/swift-quality-gate.sh` and
  `scripts/compile-and-run.sh`.
- README should gain an install section near the existing build/test/run
  instructions.
- If bundle checks are added, they should validate the Xcode-built `.app`, not
  the SwiftPM executable.
- If uninstall or reset helpers are added, they must distinguish the copied app
  bundle from `~/Library/Application Support/Kubebar/config.json`.

</code_context>

<specifics>

## Specific Ideas

- The primary user command can be a single local installer such as
  `./scripts/install-local.sh`.
- The default install destination should be user-owned, for example
  `~/Applications/Kubebar.app`.
- The update story should be "run the same install command again".
- The uninstall story should be "quit Kubebar and remove the copied app bundle".
- Config reset should be documented as a separate step that removes
  `~/Library/Application Support/Kubebar/config.json` or the whole Kubebar
  application-support directory after explaining the consequence.
- Bundle proof should include existence of `Kubebar.app`, app metadata, and app
  assets, rather than only a successful build command.

</specifics>

<deferred>

## Deferred Ideas

- Developer ID signing.
- Notarization.
- Homebrew formula or tap.
- Sparkle or automatic update checks.
- pkg or dmg installer artifact.
- GitHub release automation.
- Public release documentation.
- `Open in k9s` or deeper-debugging handoff.

</deferred>

---

*Phase: 08-prepare-local-macos-distribution*
*Context gathered: 2026-04-22*
