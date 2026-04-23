# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Refined project documentation with a focus on productization.
- New `docs/PERMISSIONS.md` providing transparency on `kubectl` usage and data privacy.
- New `docs/RELEASING.md` outlining the Ad-hoc signing and release checklist.
- Professionalized `README.md` with visual placeholders, installation guides, and a "Trusting this App" FAQ.
- Standardized `CHANGELOG.md` format.

### Fixed
- Improved clarity of `kubectl` dependency requirements in onboarding docs.

## [0.1.0] - 2026-04-23

### Added
- Initial project foundation: SwiftUI menu bar app.
- Core health states: `OK`, `Watch`, `Bad`, `Stale`.
- Watchlist-first display model and stale-data handling.
- Local configuration persistence for context and workloads.
- `kubectl` JSON snapshot integration.
- First-use setup and watchlist editing views.
- Warning event summaries and workload status reasons.
- Basic quality gate scripts and local installation support.
