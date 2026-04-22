# Phase 08: Prepare Local macOS Distribution - Pattern Map

**Mapped:** 2026-04-22
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
| --- | --- | --- | --- | --- |
| `scripts/install-local.sh` | script | build-artifact -> local install | `scripts/compile-and-run.sh` | strong |
| `scripts/swift-quality-gate.sh` | script dependency | verification | `scripts/swift-quality-gate.sh` | exact |
| `README.md` | docs | user command reference | `README.md` | exact |
| `CHANGELOG.md` | docs | release note | `CHANGELOG.md` | exact |
| `.planning/phases/08-prepare-local-macos-distribution/08-UAT.md` | verification doc | manual evidence | `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md` | role-match |
| `project.yml` | build source of truth | app metadata | `project.yml` | exact |
| `Package.swift` | package parity | SwiftPM build/test | `Package.swift` | exact |
| `docs/architecture/runtime-invariants.md` | product guardrail | runtime contract | `docs/architecture/runtime-invariants.md` | exact |
| `.planning/codebase/TESTING.md` | verification map | test commands | `.planning/codebase/TESTING.md` | exact |

## Pattern Assignments

### `scripts/install-local.sh` (script, build-artifact -> local install)

**Analog:** `scripts/compile-and-run.sh`

**Repository-root resolution pattern:**

```bash
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
```

**Build output path pattern:**

```bash
CONFIGURATION="${XCODE_CONFIGURATION:-Debug}"
DERIVED_DATA_PATH="${XCODE_DERIVED_DATA_PATH:-DerivedData}"
APP_NAME="Kubebar"
BUNDLE_ID="com.nextty.kubebar"
APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
```

**Quality gate reuse pattern:**

```bash
XCODE_WORKSPACE="" \
  XCODE_PROJECT="${XCODE_PROJECT:-Kubebar.xcodeproj}" \
  XCODE_SCHEME="${XCODE_SCHEME:-Kubebar}" \
  XCODE_CONFIGURATION="$CONFIGURATION" \
  XCODE_DERIVED_DATA_PATH="$DERIVED_DATA_PATH" \
  ./scripts/swift-quality-gate.sh local
```

**Targeted quit pattern:**

```bash
osascript -e "tell application id \"${BUNDLE_ID}\" to quit" >/dev/null 2>&1 || true
```

**Planner note:** Reuse these patterns, but default the installer to `Release`
and copy the app instead of launching the DerivedData build.

### `scripts/swift-quality-gate.sh` (script dependency, verification)

**Analog:** `scripts/swift-quality-gate.sh`

**Key behavior to preserve:**

- Detects Xcode project/workspace and scheme.
- Runs Xcode build and test.
- Runs `swift build` and `swift test` when `Package.swift` exists.
- Honors `XCODE_PROJECT`, `XCODE_SCHEME`, `XCODE_CONFIGURATION`,
  `XCODE_DESTINATION`, and `XCODE_DERIVED_DATA_PATH`.

**Planner note:** The installer should call this script, not duplicate the whole
quality gate.

### `README.md` (docs, user command reference)

**Analog:** current `README.md`

**Existing section pattern:**

The README uses short headings followed by copyable command blocks. Add local
install instructions near `## Build and Test` and keep each operation in its
own small command block.

**Planner note:** Add local install instructions near Build and Test. Keep
commands copyable and separate install/update/uninstall/reset.

### `CHANGELOG.md` (docs, release note)

**Analog:** current `CHANGELOG.md`

**Existing pattern:**

```markdown
## [Unreleased]

### Added
- Initial project setup
```

**Planner note:** Add a short `Added` bullet for local install support. Do not
invent a release version.

### `.planning/phases/08-prepare-local-macos-distribution/08-UAT.md`

**Analog:** `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md`

**Useful pattern:**

- YAML frontmatter with `status`, `phase`, `source`, `started`, and `updated`.
- Tables separating automated verification from manual/human checks.
- Scope guard table that records what was not introduced.

**Planner note:** For Phase 08, use UAT to record bundle/install evidence and
scope guards around signing, notarization, Homebrew, pkg/dmg, Sparkle, and app
behavior.

### `project.yml` (build source of truth, app metadata)

**Existing app settings:**

```yaml
PRODUCT_BUNDLE_IDENTIFIER: com.nextty.kubebar
PRODUCT_NAME: Kubebar
ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
GENERATE_INFOPLIST_FILE: YES
INFOPLIST_KEY_CFBundleDisplayName: Kubebar
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.developer-tools
INFOPLIST_KEY_LSUIElement: YES
```

**Planner note:** Plan should not modify `Kubebar.xcodeproj` directly. If any
app metadata setting must change, change `project.yml` and run
`xcodegen generate`.

## Pattern Risks

- `scripts/compile-and-run.sh` uses Debug by default; `install-local.sh` should
  use Release by default.
- Existing scripts use targeted app termination. Keep that scope; do not use
  broad process cleanup.
- Existing quality gate passes `CODE_SIGNING_ALLOWED=NO` to Xcode. Do not plan
  Developer ID signing in Phase 08.
- Bundle proof must inspect the Xcode-built `.app`, not SwiftPM output.

## PATTERN MAPPING COMPLETE
