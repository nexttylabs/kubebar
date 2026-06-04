# Kubebar macOS UI pattern polish requirements

## Goal

Make the menu and Settings UI feel more like a native macOS menu-bar utility,
using standard SwiftUI desktop controls before adding custom visual chrome.

## Scope

- Keep Kubebar menu-bar-only.
- Keep the menu compact, watchlist-first, and footer-visible.
- Keep Settings as a dedicated `Settings` scene.
- Present Settings as preference-style tabs: one fixed app-wide tab first,
  followed by dynamic context tabs.
- Use standard sections, grouped preference rows, and system materials instead
  of heavier custom card chrome.

## Constraints

- Do not change health evaluation, refresh behavior, context persistence, or
  watchlist semantics.
- Do not move refresh cadence into the menu.
- Do not introduce macOS 26-only APIs while the app targets macOS 14.
- Do not use full-screen screenshots as evidence.

## Readiness

Ready for a focused implementation plan. The primary risk is visual regression
in the Settings tab selector and menu footer accessibility.

## Next Action

Create a small executable plan, then update Settings and menu footer views.
