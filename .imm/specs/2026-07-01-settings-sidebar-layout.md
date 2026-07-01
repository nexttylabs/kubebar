---
title: "refactor: Settings sidebar detail layout"
type: refactor
status: planned
date: 2026-07-01
---

# refactor: Settings sidebar detail layout

## Output Language

Spec prose is English. Schema fields, commands, file paths, Swift identifiers, canonical terms, and Immune-Brain fields stay literal.

## Goal

Redesign Kubebar Settings from a stacked `TabView` form into a clearer macOS-style sidebar/detail layout. The work should make App Settings feel structured instead of appended, give `AI Diagnostic Assistant` its own focused page, and preserve existing Settings behavior and persistence.

## Problem

The current Settings window renders all app-wide settings as one long `App Settings` page and appends `AI Diagnostic Assistant` below General, Kubeconfig, Launch, and Alerts. This makes unrelated concerns look equally weighted, creates a simple stacked-controls feel, and gives AI configuration no local information hierarchy even though it has provider, endpoint, credential, and connection-test concepts.

## Confirmed Direction

- Use a Settings sidebar with App-level pages and Context pages.
- App pages are `General`, `Kubernetes`, `Notifications`, and `AI Assistant`.
- Context pages continue to edit exactly one per-context watchlist.
- `AI Assistant` is a dedicated App page, not a bottom section on a long App Settings page.
- Keep a standard native macOS visual direction using inherited SwiftUI/system colors and typography.
- Prioritize structure, spacing, and information hierarchy over decorative styling.

## Requirements

- R1: Replace the one-long-page App Settings presentation with sidebar navigation and a detail pane.
- R2: Preserve App-level configuration behavior for refresh cadence, explicit kubeconfig paths, Start at Login, Health State Shift Alerts, and AI Provider configuration.
- R3: Preserve Context Settings behavior for per-context watchlist editing.
- R4: The Settings footer save action remains stable and predictable; local actions such as `Add Files` and `Test Connection` stay inside their relevant detail page.
- R5: The `AI Assistant` page groups content as Provider, Endpoint, Credentials, and Connection.
- R6: The `AI Assistant` page states that Test Connection is manual, API keys live in macOS Keychain, and Kubernetes data is not sent by Test Connection.
- R7: `OpenAI-compatible` remains the only provider that shows `Base URL`; no custom-header UI is introduced.
- R8: The detail pane scrolls when content is long while the window footer remains reachable.
- R9: Form rows keep safe field widths instead of stretching across the full detail pane.
- R10: The redesign does not change AI safety behavior, provider request behavior, Keychain storage behavior, Health category evaluation, or menu-bar health display.

## Non-goals

- No new AI provider, diagnostic request, warning explanation, chat surface, or automatic diagnosis.
- No new Keychain behavior beyond preserving the already planned credential flow.
- No Kubernetes read/write behavior changes.
- No new visual theme, brand palette, custom icons, animations, or rich marketing-style UI.
- No rewrite of the menu bar dropdown.

## Page Design Contract

- Page type: macOS Settings / forms.
- Design tier: Standard.
- Visual source: existing native SwiftUI Settings-style UI; no root `DESIGN.md` exists.
- Theme and palette: inherited system appearance.
- Main structure: sidebar on the left, detail pane on the right, footer at bottom.
- Sidebar groups: App and Contexts.
- App detail pages:
  - `General`: refresh cadence and launch behavior.
  - `Kubernetes`: kubeconfig discovery and explicit file list.
  - `Notifications`: Health State Shift Alerts.
  - `AI Assistant`: optional manual provider configuration and Test Connection.
- Context detail pages: existing watchlist picker for the selected Kubernetes context.
- Form bounds: fixed label width around the existing 140pt pattern; field max width approximately 320-380pt; helper text max width approximately 460pt.
- Window bounds: may grow from the current 640pt width if needed to fit sidebar plus readable detail forms.

## Acceptance Criteria

- Users can navigate App pages and Context pages from a sidebar.
- AI configuration is no longer visually appended to an unrelated long App Settings page.
- Existing save behavior still preserves refresh cadence, kubeconfig paths, Start at Login, Health State Shift Alerts, AI Provider metadata, provider API key save semantics, and per-context watchlists.
- Existing provider picker still excludes `Ollama` and includes `OpenAI-compatible`.
- `Test Connection` remains a manually pressed local action.
- Full Swift quality gate passes.
- A visible Settings smoke check confirms the sidebar/detail hierarchy, AI page grouping, conditional Base URL, and stable footer.

## Risks

- Renaming tab-oriented state to page-oriented state may touch many tests; keep changes mechanical and covered by `SetupFlowStateTests` and `MenuRuntimeStateTests`.
- Sidebar/detail layout may need a slightly wider window; avoid cramped fields rather than forcing the existing 640pt width.
- UI-only refactor can accidentally change save semantics; focused state tests must guard completed config behavior.
- Visible layout quality is partly HITL because no automated SwiftUI snapshot tests exist.
