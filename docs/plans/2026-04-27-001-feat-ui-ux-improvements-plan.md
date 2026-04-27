---
title: feat: UI/UX Improvements for Kubebar Menu
type: feat
status: completed
date: 2026-04-27
---

# feat: UI/UX Improvements for Kubebar Menu

## Overview

Apply a set of UI/UX improvements to the Kubebar menu to enhance visual appeal, usability, and native feel on macOS. This includes transitioning to a native Segmented Control for navigation, adding visual progress bars to resource cards (Overview, Nodes, Pods), and improving text contrast and data hierarchy for better glanceability.

---

## Problem Frame

The current Kubebar UI uses custom button-style tabs and text-heavy data displays. While functional, it can be improved by leveraging macOS native controls (Segmented Control) and utilizing visual indicators (progress bars, status pills, animated dots) to reduce cognitive load. Text contrast in muted areas needs a slight boost to ensure accessibility against the glassmorphism background.

---

## Scope Boundaries

- Update visual presentation in existing SwiftUI views (`MenuBarRootView`, `OverviewTabView`, `NodeDetailsView`, `PodsTabView`).
- Extend existing display models in `KubebarCore` to provide necessary fractional values (e.g., CPU/Memory percentages) if they don't already.
- Do NOT rewrite the underlying kubectl fetching logic or health evaluation rules; this is purely a presentation-layer enhancement.

---

## Context & Research

### Relevant Code and Patterns

- `Kubebar/Views/MenuBarRootView.swift` (Tab navigation)
- `Kubebar/Views/OverviewTabView.swift` (Metrics cards & Recent warnings)
- `Kubebar/Views/NodeDetailsView.swift` (Nodes list)
- `Kubebar/Views/PodsTabView.swift` (Pods list)
- `KubebarCore/Models/MenuDisplayModel.swift` (View models that may need to expose raw percentages)

### Institutional Learnings

- macOS Menu Bar apps benefit from high-contrast text and native controls to feel like first-class citizens.
- Using SF Symbols alongside text in tabs improves recognition speed.

---

## Key Technical Decisions

- **Segmented Control for Navigation:** We will replace the custom button-style tabs with `Picker` using `.pickerStyle(.segmented)` to match native macOS design.
- **Resource Progress Bars:** We will introduce a reusable `ResourceProgressBar` view and integrate it into `OverviewCardView`, `NodeRowView`, and `PodRowView`.
- **Status Pills:** We will refactor text-based status labels (e.g., "Ready") into capsule-shaped indicators with semantic background colors.

---

## Open Questions

### Resolved During Planning

- **How to get percentage data for progress bars?** We will add `cpuPercentage: Double?` and `memoryPercentage: Double?` to the relevant display models (`OverviewCardDisplay`, `NodeItemDisplay`, `PodItemDisplay`) so the views can render the bars.

### Deferred to Implementation

- The exact tint colors and opacities for the progress bars and status pills will be fine-tuned during implementation to ensure they look good against both light and dark mode glassmorphism backgrounds.

---

## Implementation Units

- U1. **Navigation & Layout Updates**

**Goal:** Update `MenuBarRootView` to use a native segmented control and add SF Symbols to the tabs.

**Files:**
- Modify: `Kubebar/Views/MenuBarRootView.swift`
- Modify: `KubebarCore/Models/MenuDisplayModel.swift` (MenuTab enum for icons)

**Approach:**
- Update `MenuTab` enum to include an `sfSymbol` property.
- Update the `Picker` in `MenuBarRootView` to use a `Label(tab.label, systemImage: tab.sfSymbol)` instead of just `Text`.
- Adjust padding between the tab picker and the main content area for better breathing room.

**Test scenarios:**
- Test expectation: none -- pure UI presentation change.

**Verification:**
- The menu uses a standard macOS segmented control and displays icons next to the text.

---

- U2. **Overview Cards Progress Bars**

**Goal:** Add horizontal progress bars to the CPU and Memory cards on the Overview tab.

**Files:**
- Modify: `Kubebar/Views/OverviewTabView.swift`
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`

**Approach:**
- Add a `progress: Double?` field to `OverviewCardDisplay`.
- Create an `InlineProgressBar` SwiftUI component.
- In `OverviewCardView`, conditionally render the `InlineProgressBar` at the bottom of the card if `progress` is provided. Use semantic colors (blue for <70%, orange for 70-90%, red for >90%).
- Emphasize the "Recent Warnings" header by bolding it and adding a warning icon.

**Test scenarios:**
- Test expectation: none -- pure UI presentation change.

**Verification:**
- Overview cards display a visual bar representing the load. Recent warnings header is more prominent.

---

- U3. **Nodes Tab Enhancements**

**Goal:** Replace text-based resource percentages with inline bars and use status pills for readiness.

**Files:**
- Modify: `Kubebar/Views/NodeDetailsView.swift`
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`

**Approach:**
- Add `cpuProgress: Double?` and `memoryProgress: Double?` to `NodeItemDisplay`.
- Update `NodeRowView` to use `InlineProgressBar` next to or below the CPU/Memory labels.
- Refactor the `statusLabel` to have a capsule background with a semantic fill color (e.g., green for Ready, red/yellow for NotReady).

**Test scenarios:**
- Test expectation: none -- pure UI presentation change.

**Verification:**
- Node rows clearly show resource usage via bars and readiness via a colored pill.

---

- U4. **Pods Tab Enhancements**

**Goal:** Improve hierarchy with namespace icons, add resource bars, and pulse transitional states.

**Files:**
- Modify: `Kubebar/Views/PodsTabView.swift`
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`

**Approach:**
- Add a folder icon (`folder.fill`) next to the namespace name in `PodNamespaceSectionView`.
- Apply a subtle background or bold text to the namespace header to differentiate it from the pod rows.
- If transitional states (e.g., `watch` / ContainerCreating) are present, use an animated pulsing effect on the status dot in `PodRowView`.

**Test scenarios:**
- Test expectation: none -- pure UI presentation change.

**Verification:**
- Namespaces are clearly separated. Transitional pods have a visual pulsing indicator.

---

- U5. **Accessibility & Polish**

**Goal:** Ensure text contrast meets standards and layout is perfectly aligned.

**Files:**
- Modify: `Kubebar/Views/MenuFooterView.swift`
- Modify: `Kubebar/Views/PodsTabView.swift`

**Approach:**
- Audit `foregroundStyle(.secondary)` and `.tertiary` usages. Ensure critical secondary text (like "Last checked") has sufficient opacity against the background.
- Ensure the "x/y" pod readiness counts are right-aligned cleanly along the edge.

**Test scenarios:**
- Test expectation: none -- pure UI presentation change.

**Verification:**
- All text is readable in both light and dark modes. Layouts are strictly aligned.
