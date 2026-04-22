---
title: "feat: Clarify Recent Warnings rows"
type: feat
status: active
date: 2026-04-22
origin: docs/brainstorms/2026-04-22-kubebar-overview-design-requirements.md
---

# feat: Clarify Recent Warnings rows

## Overview

Improve the `Recent Warnings` rows so the Overview communicates warning cause,
affected object, recency, repetition, and useful message text more clearly. The
change stays inside the existing Overview surface and reuses the current
`kubectl` warning-event data path.

This plan assumes the previous Overview redesign work already supplies the top
status row, four Overview cards, metrics cards, and capped warning area. This
plan only strengthens warning-row content, visual hierarchy, accessibility, QA
fixtures, and docs.

## Problem Frame

The current `Recent Warnings` rows can show reason, location, age, count, and a
short message, but the requirements now ask for a clearer information hierarchy:
operators should first see what happened, then where it happened, whether it is
recent or repeated, and finally the latest useful message. The row should also
make tracked-object warnings recognizable without reintroducing `Watching`
language (see origin: `docs/brainstorms/2026-04-22-kubebar-overview-design-requirements.md`).

## Requirements Trace

- R16. Warning events remain under the `Recent Warnings` title.
- R17. Rows show warning reason, affected object, and age compactly.
- R18. No-warning state stays neutral and does not become a health claim.
- R18a. Reason becomes the primary visible label.
- R18b. Affected object uses a stable object-scope format with namespace when available.
- R18c. Recency and repeat count are visible when available.
- R18d. Latest useful message appears as secondary context.
- R18e. Long messages are shortened visibly while full text remains available through help/accessibility.
- R18f. Tracked-object warnings are visually distinct without using `Watching`.
- R18g. Warning-data unavailable state is distinct from no-warning state.
- R18h. Overflow indicator clearly points to additional warnings in Events.
- R18i. Accessibility text preserves the same information priority as the visual row.
- R19. Tracked objects remain first-screen signals through status text and pinned warning priority.
- R20. Tracked warning rows stay prioritized on Overview.
- R21. Deeper warning browsing remains in Events.

## Scope Boundaries

- No new warning data source; warning events still come through existing `kubectl` reads.
- No deep troubleshooting actions, drill-down panels, or log views.
- No new severity taxonomy beyond Kubernetes warning events and existing app health states.
- No change to node, pod, CPU, or memory card behavior.
- No reintroduction of a `Watching` section or label on Overview.
- No full redesign of the Events tab; shared row improvements may appear there if the shared row component is updated.

## Context & Research

### Relevant Code and Patterns

- `AGENTS.md` requires UI to render `MenuDisplayModel`, `HealthEvaluator` to own severity, first-screen readability, and final verification through the Swift quality gate.
- `docs/architecture/runtime-invariants.md` already requires Overview `Recent Warnings` to cap visible rows, preserve overflow in Events, keep warning rows keyboard reachable, and avoid color-only states.
- `KubebarCore/Models/MenuDisplayModel.swift` currently exposes `WarningEventDisplay` with `reason`, `location`, `age`, `occurrenceCount`, `message`, and a combined `summary`.
- `KubebarCore/Services/HealthEvaluator.swift` groups warning events by reason plus involved object, sorts tracked warnings first on Overview, caps Overview rows at 2, and shortens message text.
- `Kubebar/Views/OverviewTabView.swift` renders `Recent Warnings`, overflow count, and shared warning rows.
- `Kubebar/Views/WarningEventsView.swift` owns `WarningEventRowView`, which is currently shared by Overview and Events.
- `KubebarTests/Models/MenuDisplayModelTests.swift` already covers grouping, count, ordering, overflow, shortening, and warning unavailable cases.
- `KubebarCore/QA/MenuStateFixtureCatalog.swift` includes `warning-heavy` and `watch` states that can be strengthened into clearer warning-row fixtures.

### Institutional Learnings

- Kubebar must remain a glanceable menu bar tool, not a `k9s` replacement.
- Long names and warnings should use one-line middle truncation, tooltip/help text, and accessibility labels.
- Visual/menu changes still need human-visible QA evidence or an explicit `pending-human-verification` note.

### External References

- None. Local SwiftUI patterns and existing Kubernetes event data are sufficient.

## Key Technical Decisions

- **Keep warning shaping in the display model:** Add any new row fields or labels to `WarningEventDisplay` or adjacent Overview display data so SwiftUI renders decisions rather than deriving product meaning.
- **Reason-first row contract:** The primary row text should lead with reason; object scope, recency, and repeat count should be adjacent but visually secondary.
- **Make tracked status explicit in display data:** If tracked-object warnings need a marker, expose that as display data from `HealthEvaluator`; do not infer tracked state in the view from names or row order.
- **Use shared row carefully:** Updating `WarningEventRowView` can improve both Overview and Events, but Overview-specific affordances such as tracked markers or overflow text should remain Overview-owned if Events should stay simpler.
- **Preserve warning cap and Events handoff:** Overview remains capped; overflow text tells the user additional warnings are in Events.
- **No color-only distinction:** Tracked warning distinction and unavailable/empty/overflow states must be expressed by text, symbol, shape, or accessibility content, not color alone.

## Open Questions

### Resolved During Planning

- **Should warning rows be reason-first or object-first?** Reason-first, matching the requirements decision that operators scan for failure mode before confirming the affected object.
- **Should Events get the same row treatment?** Yes for shared clarity fields and accessibility; no for Overview-only tracked emphasis unless it also improves Events without adding noise.
- **Should overflow open or navigate to Events?** No new navigation behavior in this plan; overflow text only clarifies that Events contains additional rows.

### Deferred to Implementation

- **Exact tracked marker styling:** Choose during UI work based on the current menu width and whether a small symbol, label, or accent line reads best.
- **Exact row typography and spacing:** Tune during implementation against the current 360-point menu width while preserving stable row height and readability.

## Implementation Units

- [x] **Unit 1: Strengthen warning row display contract**

**Goal:** Make warning row data explicit enough to support reason-first visual rows, tracked markers, repeat labels, and ordered accessibility text.

**Requirements:** R17, R18a, R18b, R18c, R18d, R18e, R18i, R19, R20

**Dependencies:** None

**Files:**
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`
- Modify: `KubebarCore/Services/HealthEvaluator.swift`
- Test: `KubebarTests/Models/MenuDisplayModelTests.swift`

**Approach:**
- Extend the warning display shape with fields that separate primary reason, object scope, recency, repeat label, optional message, optional tracked marker, and accessibility summary.
- Keep the existing grouped-warning behavior: group by reason plus involved object, count repeated events, preserve newest observed time, and keep newest useful message.
- Mark Overview warning rows that match tracked-object warnings using data produced from `HealthEvaluator`'s existing pinned warning IDs.
- Keep Events rows compatible with the same model without requiring tracked emphasis.
- Preserve message shortening and ensure full message text remains available for view help/accessibility.

**Execution note:** Start with model-level tests so the row contract is locked before UI rendering changes.

**Patterns to follow:**
- Existing `WarningEventDisplay.summary` behavior in `MenuDisplayModel.swift`
- Existing `makeWarningEventSummaries` and `pinnedWarningIDs` logic in `HealthEvaluator.swift`

**Test scenarios:**
- Happy path: single warning with reason, namespace, object kind, object name, age, and message -> display row exposes reason as primary text, object scope separately, age separately, and message as secondary text.
- Happy path: repeated warning count greater than 1 -> display row exposes a repeat label such as `x4` without burying the object or age.
- Happy path: tracked warning appears in Overview rows -> display row exposes tracked emphasis while Events rows do not require the same emphasis.
- Edge case: missing namespace or object kind -> object scope still uses a stable fallback and does not collapse into an empty string.
- Edge case: long message -> visible message is shortened and full text remains available through a full-message/accessibility field.
- Regression: Overview warning ordering still pins tracked warnings first and caps visible rows.
- Regression: existing Events tab warning rows can still render from the updated display model.

**Verification:**
- Warning row display data answers: what happened, where, how recent, repeated or not, and latest useful message.
- Views do not need to infer tracked status or parse `summary` text.

- [x] **Unit 2: Redesign warning row rendering**

**Goal:** Update the shared warning row UI so Overview rows are clearer while preserving compact menu-bar readability and keyboard access.

**Requirements:** R16, R17, R18a, R18b, R18c, R18d, R18e, R18f, R18i, R21

**Dependencies:** Unit 1

**Files:**
- Modify: `Kubebar/Views/WarningEventsView.swift`
- Modify: `Kubebar/Views/OverviewTabView.swift`
- Test: `KubebarTests/Models/MenuDisplayModelTests.swift`

**Approach:**
- Render the first visual line as reason-first, with object scope, age, and repeat count placed so they are quickly scannable.
- Render message text as secondary context and keep it from visually competing with the first line.
- Add a non-color-only tracked-object indicator for Overview rows when display data says the warning is tracked.
- Keep rows compact enough that the existing Overview cap keeps top row and cards visible.
- Preserve `help(...)`, middle truncation for long names, and combined accessibility labels.
- Keep focusability on individual warning rows and preserve Overview focus order.

**Patterns to follow:**
- Existing one-line truncation and `help(Text(...))` patterns in `OverviewCardView` and `WarningEventRowView`
- Existing `.accessibilityElement(children: .combine)` and `.focusable()` usage in warning rows

**Test scenarios:**
- Test expectation: none for visual styling itself; behavior is covered through display-model tests and QA fixtures.
- Integration: accessibility label generated by the row display data should include reason, object scope, age, repeat label, and message in that order.

**Verification:**
- Recent warning rows visually lead with reason.
- Long object names or messages do not overflow their parent row.
- Tracked-object warning distinction remains readable without using `Watching`.

- [x] **Unit 3: Clarify empty, unavailable, and overflow states**

**Goal:** Make `Recent Warnings` section states unambiguous: no warnings, warning data unavailable, and more warnings in Events.

**Requirements:** R18, R18g, R18h, R18i, R21

**Dependencies:** Unit 1

**Files:**
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`
- Modify: `KubebarCore/Services/HealthEvaluator.swift`
- Modify: `Kubebar/Views/OverviewTabView.swift`
- Test: `KubebarTests/Models/MenuDisplayModelTests.swift`

**Approach:**
- Keep no-warning copy neutral and avoid health claims.
- Keep warning-unavailable copy clearly distinct from empty state and include the safe reason when available.
- Replace bare `+N` overflow, if needed, with clearer text or accessible label that says more warnings are in Events.
- Ensure overflow count is based on grouped warning rows, not raw event records, if implementation shows the current raw count can mislead after grouping.

**Patterns to follow:**
- Existing `warningEventsEmptyMessage` and `tabUnavailableMessage` helpers in `HealthEvaluator.swift`
- Existing Overview overflow rendering in `RecentWarningsOverviewView`

**Test scenarios:**
- Happy path: no warning events with available warning section -> empty text remains neutral and does not say the cluster is healthy.
- Error path: warning events section unavailable -> Overview shows unavailable copy and does not show no-warning empty text.
- Happy path: more grouped warnings than Overview cap -> overflow copy/accessibility says additional warnings are in Events.
- Edge case: duplicate raw events group into one row -> overflow count reflects the user-visible additional rows, not raw duplicate event count.
- Regression: Events tab still receives its fuller capped list independently of Overview.

**Verification:**
- Empty, unavailable, and overflow states cannot be confused by sighted users or accessibility users.

- [x] **Unit 4: Update QA fixtures, docs, and generated evidence text**

**Goal:** Keep deterministic QA states and docs aligned with the clearer warning-row design.

**Requirements:** R16, R18a, R18f, R18g, R18h, R18i

**Dependencies:** Units 1-3

**Files:**
- Modify: `KubebarCore/QA/MenuStateFixtureCatalog.swift`
- Modify: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Modify: `docs/qa/operator-verification.md`
- Modify: `scripts/generate-qa-evidence.sh`
- Test: `KubebarTests/QA/MenuStateFixtureCatalogTests.swift`

**Approach:**
- Strengthen the `watch` and `warning-heavy` fixtures so they exercise reason-first rows, repeat count, tracked warning marker, message text, and overflow.
- Add or update fixture assertions to lock important warning-row display fields rather than only checking first reason and row count.
- Update runtime invariants to describe reason-first warning rows, tracked distinction without `Watching`, and distinct warning states.
- Update operator verification and generated evidence text so human QA knows what to inspect in `Recent Warnings`.
- Keep evidence states as `pending-human-verification` unless the menu is actually opened and checked.

**Patterns to follow:**
- Existing `warning-heavy` fixture in `MenuStateFixtureCatalog.swift`
- Existing QA evidence wording in `docs/qa/operator-verification.md` and `scripts/generate-qa-evidence.sh`

**Test scenarios:**
- Happy path: `warning-heavy` fixture exposes tracked warning first with repeat count and message.
- Happy path: `watch` fixture exposes one tracked warning with clear reason, object scope, age, repeat count, and message.
- Regression: fixture metadata still has no sensitive strings.
- Regression: fixture copy still does not describe `Watching rows` or `Watching section`.

**Verification:**
- QA fixtures and docs describe the new warning-row expectations.
- Human verification remains explicit where visual inspection is required.

## System-Wide Impact

- **Interaction graph:** `KubectlClusterReader` warning records continue into `ClusterSnapshot`, then `HealthEvaluator`, then `MenuDisplayModel`, then SwiftUI. No new Kubernetes read is introduced.
- **Error propagation:** Warning-event read failures still become safe unavailable messages, not no-warning states.
- **State lifecycle risks:** Stale displays must not make old warning rows look current; existing stale banner behavior remains the freshness signal.
- **API surface parity:** Overview and Events share warning-row data. Any model change should preserve both surfaces.
- **Integration coverage:** Model tests should cover warning grouping, ordering, tracked emphasis, overflow, unavailable state, and accessibility text.
- **Unchanged invariants:** Menu bar health categories, top Overview row, four cards, watchlist priority, and Events tab availability remain unchanged.

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Warning rows become too dense for the menu width | Keep two-line maximum row shape, use truncation/help text, and preserve the Overview cap. |
| Tracked marker accidentally reintroduces `Watching` language | Use a small non-color-only marker or label that avoids the `Watching` word, and add fixture/text regression coverage. |
| Shared row changes make Events noisier | Keep Overview-specific emphasis optional in display data and render only where it helps. |
| Overflow count misleads after event grouping | Prefer grouped-row overflow semantics and test duplicate raw events. |
| Accessibility lags behind visual row changes | Build accessibility summary from display data and test the ordered content. |

## Documentation / Operational Notes

- Update `docs/architecture/runtime-invariants.md` because warning-row hierarchy and state distinctions are runtime product rules.
- Update `docs/qa/operator-verification.md` and `scripts/generate-qa-evidence.sh` so QA checks call out reason-first rows, tracked warning distinction, repeat count, and overflow.
- Run the repo quality gate during implementation. Keep visible menu QA as `pending-human-verification` until screenshots or an explicit human check exist.

## Sources & References

- **Origin document:** [docs/brainstorms/2026-04-22-kubebar-overview-design-requirements.md](docs/brainstorms/2026-04-22-kubebar-overview-design-requirements.md)
- Existing plan: [docs/plans/2026-04-22-001-feat-overview-cluster-cards-plan.md](docs/plans/2026-04-22-001-feat-overview-cluster-cards-plan.md)
- Runtime invariants: [docs/architecture/runtime-invariants.md](docs/architecture/runtime-invariants.md)
- Display model: [KubebarCore/Models/MenuDisplayModel.swift](KubebarCore/Models/MenuDisplayModel.swift)
- Health mapping: [KubebarCore/Services/HealthEvaluator.swift](KubebarCore/Services/HealthEvaluator.swift)
- Overview view: [Kubebar/Views/OverviewTabView.swift](Kubebar/Views/OverviewTabView.swift)
- Warning rows: [Kubebar/Views/WarningEventsView.swift](Kubebar/Views/WarningEventsView.swift)
