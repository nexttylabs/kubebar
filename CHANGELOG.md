# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]




## [0.5.0] - 2026-06-22

### Added
- add pod log focus window
- add pod log focus window and micro logs drawer
- Add a focusable Pod log window for inspecting recent logs from Bad Pod rows.

### Changed
- streamline kubebar data flow

### Fixed
- address pod log window review blockers

### Documentation
- improve kubebar README conversion hooks

## [0.4.0] - 2026-06-04

### Added
- Add optional Health State Shift Alerts in Settings so Kubebar can notify users when cluster health or watched workloads worsen.

### Changed
- 添加 Health State Shift Alerts 并补充 Settings 配置
- 重构 Settings 与 Context 管理，支持自定义导入和启用禁用
- Add changelog fragment for health alerts
- Add health shift alerts with stable workload identities
- Add per-context watchlists and context selector
- auto publish merged release notes
- Capture per-context watchlist guidance
- Fix kubeconfig path handling in Settings and launch scripts
- ignore DerivedData*
- improve settings ui
- Make release workflow explicit and manual
- Merge remote-tracking branch 'origin/main'
- Refine settings layout and local context tabs
- remove derived data
- Sync release build metadata across app bundle
- Split Settings into app-wide and per-context tabs, and move context switching into a nested menu selector.

### Fixed
- resolve reviewer feedbacks

## [0.3.2] - 2026-05-27

### Changed
- open changelog candidate prs
- Pause refresh while network is offline

### Fixed
- correct changelog workflow syntax
- upload custom changelog candidates

## [0.3.0] - 2026-05-19

### Added
- Add a Settings toggle for Start at Login so users can launch Kubebar automatically after signing in.

## [0.3.1] - 2026-05-19

### Added
- Add a Settings toggle for Start at Login so users can launch Kubebar
- automatically after signing in.

## [0.2.4] - 2026-05-15

### Added
- Add `Open in k9s` handoffs for fresh attention rows, Pod namespace groups, and the Nodes summary.

### Fixed
- Keep Pod and Node k9s handoff buttons at the list level they actually open, avoiding misleading row-level resource jumps.

## [0.2.3] - 2026-05-14

### Added
- Add current CPU and memory usage indicators for watched Pods.
- Add app screenshots, permission notes, and release guidance to help users evaluate and install Kubebar.

### Changed
- Improve Pod resource labels, hover details, and compact row readability.
- Refine project documentation with a stronger productization focus.

### Fixed
- Preserve Pod resource progress data when building menu display rows.
- Improve clarity of `kubectl` dependency requirements in onboarding docs.

## [0.2.2] - 2026-04-28

### Fixed
- Stop treating historical Pod restart counts as active failures after the Pod has recovered.

## [0.2.1] - 2026-04-27

### Added
- Add changelog fragments and release-note validation for safer GitHub Releases.

### Changed
- Improve menu status visuals with clearer navigation icons, resource bars, and Pod transition indicators.

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
