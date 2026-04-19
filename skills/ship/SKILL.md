---
description: Run the Swift iOS quality gate before shipping.
allowed-tools:
  - Bash(./scripts/swift-quality-gate.sh:*)
  - Bash(swift:*)
  - Bash(xcodebuild:*)
---

# Ship

Run the Swift quality gate. Stop on the first failure and fix it before continuing.

1. **Build**: `./scripts/swift-quality-gate.sh local`
2. **Docs check**: update `README.md`, `docs/`, or `CHANGELOG.md` if behavior changed

If your project has multiple workspaces, projects, or schemes, set `XCODE_WORKSPACE`, `XCODE_PROJECT`, `XCODE_SCHEME`, and `XCODE_DESTINATION` before running the quality gate.
