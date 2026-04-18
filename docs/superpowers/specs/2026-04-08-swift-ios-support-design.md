# Swift iOS Support Design

## Goal

Add Swift support to the project template for iOS application teams without forcing a fixed Xcode app skeleton.

## Scope

- Add `swift` as a first-class language option in template setup
- Add a complete `_lang/swift/` overlay matching the existing language model
- Support common iOS app projects driven by Xcode
- Keep `SwiftLint` optional rather than required

## Non-Goals

- Do not generate a starter Xcode app project
- Do not require `Tuist`, `xcodegen`, `fastlane`, or `SwiftLint`
- Do not guess through multi-workspace or multi-scheme repositories without explicit input

## Design

### Language Overlay

Add `_lang/swift/` with the same contract used by the other languages:

- `AGENTS.md`
- `ci.yml`
- `commit-msg.partial`
- `labeler.yml`
- `pre-push.partial`
- `review-discipline.md`
- `ship.md`
- `testing.md`
- `.gitignore`

### Setup and Detection

Extend `init.sh` so `swift` is available in the language selector and copied like the other overlays.

Extend `scripts/dev-setup.sh` to detect Swift repositories by:

- `Package.swift`
- `*.xcodeproj`
- `*.xcworkspace`
- `Swift Guide` marker in `AGENTS.md`

For Swift projects, require:

- `swift`
- `xcodebuild`

Recommend:

- `swiftlint`

### Quality Gate

Add a reusable script for Swift quality checks. It should:

- Run `swift build` and `swift test` for package-only repositories
- Run `xcodebuild build` and `xcodebuild test` for Xcode-based repositories
- Auto-detect a single workspace or project
- Auto-detect a single scheme
- Fail with a clear message when multiple candidates exist and explicit configuration is needed

The script should accept environment overrides:

- `XCODE_WORKSPACE`
- `XCODE_PROJECT`
- `XCODE_SCHEME`
- `XCODE_CONFIGURATION`
- `XCODE_DESTINATION`

### CI

Use a macOS runner and call the shared Swift quality gate script instead of duplicating logic in YAML.

### Regression Test Detection

Treat the following as test changes:

- `Tests/**`
- `UITests/**`
- files ending in `Tests.swift`
- files ending in `Spec.swift`
- files ending in `SnapshotTests.swift`
- Swift files containing `XCTestCase`, `QuickSpec`, or snapshot assertions

### Documentation

Update `README.md` so Swift appears anywhere the template lists supported languages, setup choices, and quality tools.

## Validation

- `init.sh` exposes `swift`
- Swift overlay files exist and are copied during initialization
- Swift projects are detected by `scripts/dev-setup.sh --check-only`
- Shared Swift quality gate script runs in a simulated Xcode project flow
