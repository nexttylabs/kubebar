# Releasing Kubebar

This document outlines the release process for Kubebar. Since the project currently does not use an Apple Developer account, releases are distributed as **Ad-hoc signed** bundles.

## Release Checklist

- [ ] **Finalize Changes**: Ensure all features and fixes for the version are merged.
- [ ] **Update Changelog**: Move entries from `[Unreleased]` to a new versioned section in `CHANGELOG.md`.
- [ ] **Version Bump**: Update the version number in `project.yml` and regenerate the project using `xcodegen`.
- [ ] **Quality Gate**: Run `./scripts/swift-quality-gate.sh local` to ensure all tests pass.
- [ ] **Build Universal App**: Build the app for both `arm64` and `x86_64` architectures.
- [ ] **Ad-hoc Signing**: Sign the app bundle with a null identity (`-`) to satisfy basic macOS requirements.
- [ ] **Package**: Create a `.zip` archive of `Kubebar.app`.
- [ ] **Tag and Publish**: Create a Git tag (e.g., `v0.1.0`) and upload the zip to a GitHub Release.

## Ad-hoc Signing & Distribution

Without an Apple Developer certificate, the app cannot be notarized. This means macOS will flag it as "unverified" when downloaded.

### Signing Command
During the build process, the app is signed using:
```bash
codesign --force --deep --sign - Kubebar.app
```

### User Guidance for Ad-hoc Apps
When users download the pre-compiled `.zip`, they will encounter Gatekeeper warnings. You **must** include the following instructions in the GitHub Release notes:

> **Note on macOS Security**:
> Kubebar is currently distributed with an Ad-hoc signature. To run it:
> 1. Download and extract the `.zip`.
> 2. Right-click `Kubebar.app` and select **Open**.
> 3. Click **Open** again in the confirmation dialog.
> 4. Alternatively, run `xattr -cr /path/to/Kubebar.app` in your terminal to remove the quarantine flag.

## Future Path: Formal Distribution

The transition to a formal release flow will require:
1. **Apple Developer Account**: For code signing and notarization.
2. **Notarytool Integration**: Automating the submission to Apple's notary service.
3. **Sparkle Appcast**: Setting up an `appcast.xml` for automated in-app updates.
4. **Homebrew Cask**: Creating a formula for `brew install --cask kubebar`.
