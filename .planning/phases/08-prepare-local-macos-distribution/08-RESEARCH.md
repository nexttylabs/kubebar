# Phase 08: Prepare Local macOS Distribution - Research

**Researched:** 2026-04-22
**Domain:** Local macOS app bundle distribution for a SwiftUI MenuBarExtra app
**Confidence:** HIGH for copied `.app` bundle install path, MEDIUM for launch
behavior on machines with stricter local signing policies because this phase
explicitly excludes Developer ID signing and notarization.

<user_constraints>

## User Constraints

Source: `.planning/phases/08-prepare-local-macos-distribution/08-CONTEXT.md`

### Locked Decisions

- Use a copied macOS `.app` bundle as the first local distribution shape.
- Build the installable app through the Xcode project path, not SwiftPM
  executable output.
- Default install destination should be user-owned, such as
  `~/Applications/Kubebar.app`.
- Do not create pkg, dmg, Homebrew, Sparkle, release automation, notarization,
  or public release artifacts.
- Run the existing local quality gate before producing the installable bundle.
- Re-running the install command is the update path and must leave user config
  intact.
- Uninstall docs must separate removing the copied app from resetting config.
- Config location is `~/Library/Application Support/Kubebar/config.json`.
- Distribution must not weaken watchlist-first display, stale-state visibility,
  the four menu bar states, or local privacy boundaries.

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Source | Requirement | Research Support |
| --- | --- | --- | --- |
| ISSUE-8-AC1 | GitHub issue #8 | A user can build and install Kubebar locally without opening Xcode. | Add a script under `scripts/` that runs the quality gate, builds `Kubebar.app`, verifies it, and copies it to a user-owned destination. |
| ISSUE-8-AC2 | GitHub issue #8 | Install docs explain where config lives and how to reset it. | Update `README.md` with install, update, uninstall, and config reset sections naming `~/Library/Application Support/Kubebar/config.json`. |
| ISSUE-8-AC3 | GitHub issue #8 | Distribution work does not weaken menu bar utility behavior. | Keep all work in scripts/docs/UAT; do not touch `Kubebar/` or `KubebarCore/` unless a bundle metadata issue requires project setting changes. |
| ISSUE-8-AC4 | GitHub issue #8 | Local quality checks pass before producing the app bundle. | Reuse `./scripts/swift-quality-gate.sh local` before copy. Verify the generated `.app` metadata and assets after build and after copy. |

</phase_requirements>

## Existing Build Shape

- `project.yml` is the XcodeGen source of truth for the macOS app target.
- `Kubebar.xcodeproj` is committed and currently builds `Kubebar.app`.
- `Package.swift` defines a SwiftPM executable, but that output is not the
  installable app bundle for this phase.
- `scripts/swift-quality-gate.sh local` runs Xcode build, Xcode tests,
  `swift build`, and `swift test`.
- `scripts/compile-and-run.sh` already locates
  `DerivedData/Build/Products/<configuration>/Kubebar.app`, quits a running
  app instance, launches the app, and prints the app path.

## Recommended Implementation Approach

### 1. Add a Local Installer Script

Create `scripts/install-local.sh` with these responsibilities:

- Use `set -euo pipefail`.
- Default `XCODE_CONFIGURATION` to `Release`.
- Default `XCODE_PROJECT` to `Kubebar.xcodeproj`.
- Default `XCODE_SCHEME` to `Kubebar`.
- Default `XCODE_DERIVED_DATA_PATH` to `DerivedData`.
- Default install directory to `${KUBEBAR_INSTALL_DIR:-$HOME/Applications}`.
- Run `./scripts/swift-quality-gate.sh local` with the selected Xcode settings.
- Locate the built app at
  `DerivedData/Build/Products/${XCODE_CONFIGURATION}/Kubebar.app`.
- Verify the built bundle before copying.
- Quit a running app with bundle id `com.nextty.kubebar` before replacement.
- Replace only `${KUBEBAR_INSTALL_DIR}/Kubebar.app`.
- Verify the copied bundle.
- Print both the built app path and installed app path.

The script should avoid broad cleanup. It may remove the existing copied
`Kubebar.app` at the install destination as part of replacement, but should not
delete any config under Application Support.

### 2. Add Bundle Metadata Checks

The installer can keep verification inline rather than adding a separate script
at first. Required checks:

- `Kubebar.app` directory exists.
- `Contents/Info.plist` exists.
- `CFBundleIdentifier` equals `com.nextty.kubebar`.
- `CFBundleDisplayName` or `CFBundleName` identifies `Kubebar`.
- `LSUIElement` is true.
- `CFBundleIconFile` equals `AppIcon`.
- `Contents/Resources/AppIcon.icns` exists.
- `Contents/Resources/Assets.car` exists.
- `Contents/MacOS/Kubebar` exists and is executable.

These checks directly protect the prior AppIcon packaging work and prove the
copied product is a real menu bar app bundle, not the SwiftPM executable.

### 3. Document Install, Update, Uninstall, and Reset

Update `README.md` near the current Build and Test section:

- Install: `./scripts/install-local.sh`.
- Optional destination override:
  `KUBEBAR_INSTALL_DIR=/Applications ./scripts/install-local.sh`.
- Update: run the same install command again.
- Uninstall: quit Kubebar and remove `~/Applications/Kubebar.app` or the custom
  destination used at install time.
- Reset config: quit Kubebar, then remove
  `~/Library/Application Support/Kubebar/config.json` or the whole
  `~/Library/Application Support/Kubebar` directory after explaining it resets
  saved context, watchlist, and refresh cadence.
- Privacy: config reset does not touch kubeconfig, Kubernetes credentials, or
  cluster state.

Update `CHANGELOG.md` under `[Unreleased]` to mention local install support.

### 4. Record Distribution UAT

Create `.planning/phases/08-prepare-local-macos-distribution/08-UAT.md` during
execution with a checklist for:

- Installer quality gate pass.
- Built bundle metadata proof.
- Installed bundle metadata proof.
- Install destination proof.
- Update path proof.
- Uninstall docs proof.
- Config reset docs proof.
- Explicit no-scope-creep proof for notarization, Homebrew, pkg/dmg, Sparkle,
  release automation, and app behavior changes.

## Risks and Pitfalls

| Risk | Why It Matters | Mitigation |
| --- | --- | --- |
| SwiftPM executable mistaken for app bundle | SwiftPM output is not `Kubebar.app` and will not carry menu bar app metadata. | Build/copy only the Xcode-built `.app` under `DerivedData/Build/Products/<configuration>/Kubebar.app`. |
| Generated project drift | `project.yml` is the durable source of truth. | If app target settings change, update `project.yml` and regenerate the project. This phase should avoid target-setting changes unless verification fails. |
| Config loss during update | The update path should not delete Application Support. | Installer replaces only the copied app bundle and docs keep reset separate. |
| Signing scope creep | Developer ID signing and notarization are explicitly deferred. | Do not require a team id or certificate. If ad-hoc signing is later needed, keep it local-only and documented as not public distribution. |
| Bundle proof too weak | A build can pass while assets or Info.plist metadata are wrong. | Verify `AppIcon.icns`, `Assets.car`, `CFBundleIconFile`, bundle id, and `LSUIElement`. |
| App behavior changes hidden in distribution phase | Issue #8 is packaging/docs, not menu behavior. | Plan should modify scripts/docs/UAT only, unless bundle metadata source-of-truth changes are strictly required. |

## Planning Recommendation

Create two plans:

1. `08-01-PLAN.md`: Add the local installer script and bundle metadata
   verification.
2. `08-02-PLAN.md`: Document install/update/uninstall/reset, update changelog,
   and create UAT evidence checklist.

No UI-SPEC or AI-SPEC is needed. No schema push, external deployment, or
notarization plan is needed.

## Validation Architecture

| Layer | Validation |
| --- | --- |
| Script syntax | `bash -n scripts/install-local.sh` |
| Quality gate reuse | `rg -n "swift-quality-gate.sh local" scripts/install-local.sh` |
| Bundle metadata | Script checks with `/usr/libexec/PlistBuddy`, `test -d`, `test -f`, and `test -x` |
| Install path | Script prints `Installed app: <path>/Kubebar.app` |
| Docs | `rg` checks for install, update, uninstall, reset, config path, and deferred public distribution terms |
| Full verification | `./scripts/install-local.sh` followed by `./scripts/swift-quality-gate.sh local` when execution environment allows app bundle build/copy |

## Open Questions

None. The first local distribution shape is locked as a copied `.app` bundle.

## RESEARCH COMPLETE
