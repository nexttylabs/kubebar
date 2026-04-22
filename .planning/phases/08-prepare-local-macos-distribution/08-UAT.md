---
status: pending-execution
phase: 08-prepare-local-macos-distribution
source:
  - 08-CONTEXT.md
  - 08-01-PLAN.md
  - 08-02-PLAN.md
---

## Automated Verification

| Check | Status | Evidence |
| --- | --- | --- |
| `bash -n scripts/install-local.sh` | pass | Script syntax check completed successfully. |
| `./scripts/install-local.sh` | pass | Debug quality gate passed, Release app bundle built, and Kubebar installed to `~/Applications/Kubebar.app`. |
| `./scripts/swift-quality-gate.sh local` | pass | Covered by the installer run; Xcode and SwiftPM checks reported 89 tests passing in each test path. |

## Bundle Proof

| Proof | Status | Evidence |
| --- | --- | --- |
| `CFBundleIdentifier = com.nextty.kubebar` | pass | Installed app Info.plist printed `com.nextty.kubebar`. |
| `LSUIElement = true` | pass | Installed app Info.plist printed `true`. |
| `CFBundleIconFile = AppIcon` | pass | Installed app Info.plist printed `AppIcon`. |
| `Contents/Resources/AppIcon.icns` | pass | Installed app bundle contains `Contents/Resources/AppIcon.icns`. |
| `Contents/Resources/Assets.car` | pass | Installed app bundle contains `Contents/Resources/Assets.car`. |
| installed app destination | pass | Installed app destination is `~/Applications/Kubebar.app`. |

## Documentation Checks

| Check | Status | Evidence |
| --- | --- | --- |
| install | pass | README contains `./scripts/install-local.sh`, the default destination, and an optional `KUBEBAR_INSTALL_DIR` override. |
| update | pass | README says local update means running the same install command again. |
| uninstall | pass | README quits `com.nextty.kubebar` and removes only `$HOME/Applications/Kubebar.app`. |
| config reset | pass | README names `~/Library/Application Support/Kubebar/config.json` and removes only that file. |
| privacy boundary | pass | README states reset does not touch kubeconfig, Kubernetes credentials, or cluster resources. |

## Scope Guards

| Guard | Status | Evidence |
| --- | --- | --- |
| no notarization | pass | README lists notarization as outside this local distribution path. |
| no Homebrew | pass | README lists Homebrew as outside this local distribution path. |
| no Sparkle | pass | README lists Sparkle as outside this local distribution path. |
| no pkg | pass | README lists pkg as outside this local distribution path. |
| no dmg | pass | README lists dmg as outside this local distribution path. |
| no public release automation | pass | README lists public release automation as outside this local distribution path. |
| no `Open in k9s` | pass | This phase changed scripts and docs only; no deeper troubleshooting handoff was added. |
| no app runtime behavior change | pass | No files under `Kubebar/` or `KubebarCore/` were modified. |

## Human Verification Required

A human may optionally launch the installed app from `~/Applications/Kubebar.app`
and confirm the menu bar item appears. This phase does not require new menu UI
automation because issue #8 is limited to local distribution, install docs, and
bundle proof.
