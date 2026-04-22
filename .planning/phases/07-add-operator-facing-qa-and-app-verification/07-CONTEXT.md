# Phase 07: Add Operator-Facing QA and App Verification - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning
**Source issue:** https://github.com/nexttylabs/kubebar/issues/7

<domain>

## Phase Boundary

This phase proves Kubebar's daily menu states against real app behavior before
local distribution work begins.

This phase delivers:

- Repeatable QA fixtures or an app verification harness for the main menu
  states.
- Evidence for Healthy, Watch, Bad, Stale, first-use, empty-watchlist, and
  kubectl failure states.
- A phase UAT record that links each state to expected behavior, result, and
  screenshot evidence.
- Long-term operator verification documentation for future manual checks.
- A quality-gate check that proves the QA fixture or checklist artifacts stay
  generatable.

This phase does not deliver:

- Local distribution, signing, notarization, or installer work.
- A full menu automation framework if macOS menu-bar inspection remains
  unreliable.
- A real-cluster-only failure requirement for kubectl failure states.
- Deep troubleshooting handoff such as `Open in k9s`.
- A dashboard or expanded monitoring surface.

</domain>

<decisions>

## Implementation Decisions

### QA Evidence Form

- **D-01:** Use a `UAT table + screenshot paths` evidence format. The table
  should be the primary review surface, and screenshot paths should point to
  the captured visual evidence.
- **D-02:** Cover all issue #7 states: Healthy, Watch, Bad, Stale, first-use,
  empty-watchlist, and kubectl failure.
- **D-03:** Each state record should be detailed. Include reproduction steps,
  expected behavior, observed behavior, evidence path, limitations, and
  follow-up risk.
- **D-04:** kubectl failure does not need to be forced through a real cluster
  as a hard completion gate. Automatic tests should prove the behavior, while
  visible-app QA confirms that the displayed state does not mislead the user.

### State Coverage

- **D-05:** Healthy should be produced from fixed fixtures or a fake runner
  that creates a fully healthy snapshot.
- **D-06:** Watch should be represented by warning events.
- **D-07:** Bad should be represented by a not-ready node or bad workload.
- **D-08:** first-use and empty-watchlist are separate states. first-use means
  setup is incomplete; empty-watchlist means a context exists but no watch
  targets are selected.
- **D-09:** Stale must cover both refresh failure with retained old data and
  old snapshot age-out.

### Automation Boundary

- **D-10:** Keep `./scripts/swift-quality-gate.sh local` as the single local
  check, but extend the gate so it also verifies that QA fixture or checklist
  artifacts can be generated.
- **D-11:** The visible-app smoke test should record the built app path, PID,
  and running state as QA evidence. It does not need to automatically open and
  inspect every menu state.
- **D-12:** If screenshot capture or real menu verification cannot complete,
  the phase may still finish only when the gap is explicit and marked
  `human_needed` or `pending-human-verification`.
- **D-13:** Add a dedicated menu-state fixture or preview harness so QA states
  are stable and do not depend on the operator's current real cluster.

### Documentation Location

- **D-14:** Use both a phase UAT file and long-term docs. The phase UAT records
  this phase's evidence; `docs/qa/operator-verification.md` keeps durable
  operator verification instructions.
- **D-15:** Store committed screenshots under `docs/assets/qa/`.
- **D-16:** Do not expand README for this phase. Update architecture or docs
  entry points instead.
- **D-17:** Manual gaps must be listed as `pending-human-verification`. Do not
  present unverified items as passed.

### the agent's Discretion

- The planner may choose the exact harness shape, file names, and command name
  as long as QA states are stable and repeatable.
- The planner may choose screenshot naming conventions under `docs/assets/qa/`.
- The planner may decide whether generated QA evidence is produced by Swift
  code, a script, or a small app mode if it preserves the product boundaries.
- The planner may tune exact UAT wording as long as every state records
  reproduction steps, observations, limitations, and risk.

</decisions>

<canonical_refs>

## Canonical References

Downstream agents MUST read these before planning or implementing.

### Product Direction

- `AGENTS.md` - repo rules and Kubebar product guardrails.
- `https://github.com/nexttylabs/kubebar/issues/7` - source issue for
  operator-facing QA and app verification.
- `docs/plans/2026-04-19-002-kubebar-product-roadmap.md` - places issue #7 as
  the readiness gate before local distribution.
- `docs/brainstorms/2026-04-19-kubebar-watchlist-first-requirements.md` -
  defines the daily operator promise and required states.

### Runtime and Architecture Rules

- `docs/architecture/runtime-invariants.md` - defines state, stale, watchlist,
  privacy, and keyboard rules that QA must verify.
- `docs/architecture/system-overview.md` - defines app, view model, core, and
  service ownership.
- `.planning/codebase/ARCHITECTURE.md` - maps app layers and data flow.
- `.planning/codebase/TESTING.md` - defines current testing patterns and
  quality gate.
- `.planning/codebase/CONCERNS.md` - records the operator-facing app
  verification gap and UI behavior test gap.

### Existing QA and Verification Context

- `scripts/swift-quality-gate.sh` - current single local quality gate.
- `scripts/compile-and-run.sh` - visible-app smoke path that builds, tests,
  launches the app, and prints process evidence.
- `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md`
  - current manual menu-state, keyboard, and long-name QA format.
- `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-VERIFICATION.md`
  - current human-needed verification result and automation limits.
- `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-CONTEXT.md`
  - prior decision that full daily-loop operator QA belongs to issue #7.

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- `scripts/swift-quality-gate.sh`: Already runs Xcode build/test and SwiftPM
  build/test; this remains the single local gate to extend.
- `scripts/compile-and-run.sh`: Already records a built app path and confirms a
  running Kubebar process by PID.
- `KubebarCore/Services/HealthEvaluator.swift`: Produces deterministic
  `MenuDisplayModel` states from snapshots, failures, and time.
- `KubebarTests/Models/MenuDisplayModelTests.swift`: Already covers many
  state mappings, including healthy, warning, bad, stale failure, and stale
  age-out behavior.
- `KubebarTests/Services/KubectlClusterReaderTests.swift`: Uses fake
  `kubectl` command output and JSON fixtures; this is the closest pattern for
  stable QA-state input.
- `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md`:
  Provides the current manual evidence table style.

### Established Patterns

- UI views render `MenuDisplayModel`; QA fixtures should prefer app-owned
  display models or fake service inputs over raw UI-only state.
- External reads go through injectable boundaries, so failure and warning
  states can be produced without mutating a real cluster.
- Stale states must never look healthy or current.
- Real macOS menu-bar inspection may require human verification when automation
  cannot inspect `MenuBarExtra.window` or `SystemUIServer`.
- Manual evidence must avoid raw command transcripts, token-like strings,
  kubeconfig paths, full JSON, or sensitive cluster data.

### Integration Points

- Add stable QA states near the existing model/service test fixtures or through
  a focused harness that can feed known `MenuDisplayModel` cases to the app.
- Add a gate check that validates QA fixture/checklist generation without
  replacing the existing build/test checks.
- Write phase evidence to
  `.planning/phases/07-add-operator-facing-qa-and-app-verification/07-UAT.md`.
- Add durable operator verification instructions at
  `docs/qa/operator-verification.md`.
- Store screenshots under `docs/assets/qa/` when screenshots are committed.

</code_context>

<specifics>

## Specific Ideas

- The evidence table is the source of truth; screenshots are supporting proof.
- Watch and Bad should not be vague labels. Watch is proven with warning events;
  Bad is proven with a not-ready node or bad workload.
- first-use and empty-watchlist need separate QA rows because they protect
  different trust promises.
- A failed kubectl path should be proven by tests and then visually checked for
  "not misleading" behavior, instead of relying on fragile real-cluster failure
  setup.
- The final result may honestly remain `human_needed` when visible menu
  traversal or screenshot capture is blocked.

</specifics>

<deferred>

## Deferred Ideas

- Local distribution, signing, notarization, and install packaging belong to
  GitHub issue #8.
- Deeper debugging handoff such as `Open in k9s` belongs to GitHub issue #9 or
  future backlog.
- A broad macOS menu automation framework is not required for this phase.

</deferred>

---

*Phase: 07-add-operator-facing-qa-and-app-verification*
*Context gathered: 2026-04-22*
