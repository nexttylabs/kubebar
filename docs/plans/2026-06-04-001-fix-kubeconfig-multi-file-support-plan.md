---
title: "fix: preserve multi-file KUBECONFIG for kubectl reads"
type: fix
status: planned
date: 2026-06-04
origin: .imm/specs/2026-06-04-kubeconfig-multi-file-support.md
---

# fix: preserve multi-file KUBECONFIG for kubectl reads

## Summary

- Summary: Support Linux/macOS colon-delimited `KUBECONFIG` by preserving the
  inherited environment value for Kubebar's `kubectl` reads.

This is a narrow config-loading fix. Kubebar should treat `KUBECONFIG` as an
opaque environment value and delegate multi-file merge behavior to `kubectl`.
The plan does not add an in-app kubeconfig path editor; that is deferred unless
GUI-launched app behavior proves inheritance is insufficient.

## Current Slice

- Roadmap source: none
- Execution scope: inherited `KUBECONFIG` preservation and tests for
  kubectl-backed reads
- Deferred phases: optional App Settings support for a user-managed kubeconfig
  file list if shell/environment inheritance is not enough for GUI-launched
  users
- This is not a full kubeconfig management roadmap.

## Task

- Type: fix
- Scope: command launch environment, kubectl service boundaries, tests, and
  runtime documentation
- Owner: imm-work
- Verification: focused Swift tests plus diff hygiene; full Swift quality gate
  when feasible
- Brainstorm manifest: BR-REQ-001; BR-REQ-002; BR-REQ-003; BR-DEC-001; BR-OUT-001; BR-Q-001

## Origin

The user noted that on Linux/macOS, `KUBECONFIG` can contain multiple files
separated by `:` and `kubectl` merges them into one effective config. They asked
how Kubebar should support reading multiple config files.

## Brainstorm Manifest

- `BR-REQ-001`: Support Linux/macOS colon-delimited multi-file kubeconfig
  values.
- `BR-REQ-002`: Keep `kubectl` responsible for kubeconfig merging.
- `BR-REQ-003`: Context list, watch target discovery, and cluster refresh must
  use one consistent kubectl environment.
- `BR-DEC-001`: Do not implement kubeconfig YAML merge logic in Kubebar.
- `BR-OUT-001`: Do not mutate kubeconfig current context or rely on the
  terminal current context.
- `BR-Q-001`: Whether Kubebar needs an App Settings kubeconfig path list instead
  of only inherited environment support.

## Brainstorm Trace

| Item | Status | Target | Reason |
| --- | --- | --- | --- |
| BR-REQ-001 | covered_by_step | U1 | U1 verifies colon-delimited `KUBECONFIG` preservation. |
| BR-REQ-002 | captured_as_decision | Decisions | The plan delegates merge behavior to `kubectl`. |
| BR-REQ-003 | covered_by_step | U1 | U1 covers command-runner and kubectl-backed reader/catalog boundaries. |
| BR-DEC-001 | captured_as_decision | Decisions | YAML merge logic is explicitly out of scope. |
| BR-OUT-001 | out_of_scope | Scope Boundaries | Current-context mutation remains outside Kubebar's app-owned context model. |
| BR-Q-001 | deferred | Current Slice | This slice supports inherited environment first; App Settings path-list support becomes a later plan only if inheritance is inadequate for GUI-launched users. |

## Research

- `CONTEXT.md` defines Kubebar as a macOS menu bar utility, app-owned context,
  and the `KUBECONFIG environment`; the plan preserves those terms.
- `docs/architecture/runtime-invariants.md` requires app-owned selected context
  as the source of truth and forbids relying on terminal current context.
- `KubebarCore/Services/CommandRunner.swift` builds process environments from
  `ProcessInfo.processInfo.environment` and currently only normalizes `PATH`.
- `KubebarCore/Services/ContextCatalog.swift` lists contexts with
  `kubectl config get-contexts -o name`.
- `KubebarCore/Services/KubectlClusterReader.swift` runs cluster reads with
  explicit `--context`.
- `KubebarCore/Services/WatchTargetCatalog.swift` discovers setup candidates
  through the same command runner boundary.
- `docs/solutions/architecture/per-context-watchlists-active-context-2026-06-03.md`
  captures the app-owned active context pattern that this plan must preserve.
- Rejected-decision scan found only pod resource history alerting, unrelated to
  kubeconfig loading.
- Planner subagent dispatch was not used: Immune-Brain activation returned no
  candidates and this is a single-domain small-scope plan.

## Decisions

- Treat `KUBECONFIG` as an opaque environment variable value.
- Preserve inherited `KUBECONFIG` for launched `kubectl` processes.
- Let `kubectl` merge multiple kubeconfig files.
- Keep app-owned selected context explicit with `--context` for reads.
- Add focused tests at the command environment boundary and reuse existing
  catalog/reader tests to prove the service boundaries remain intact.
- Defer in-app kubeconfig path-list configuration unless a later user need or
  verification result shows shell/environment inheritance is not sufficient.

## Assumptions

- The current executable slice should support users who provide `KUBECONFIG`
  through the process environment.
- Linux/macOS use `:` as the kubeconfig path-list delimiter; Windows support is
  not relevant for this macOS app.
- `kubectl`'s documented merge behavior is the source of truth for effective
  kubeconfig resolution.
- A GUI-launched app may not inherit a user's shell-only `KUBECONFIG`; this is
  visible risk, not part of the current slice.

## Devil's Advocate Audit

- Rollback resilience: The step should be limited to tests, command-boundary
  behavior, and documentation. If it fails midway, reverting the affected test,
  command-runner, and documentation changes restores the previous behavior
  without config migration or cleanup.
- Verification vanity: A test that only checks command arguments would not
  catch environment loss. U1 must include a command-runner environment test that
  can fail if `KUBECONFIG` is split, omitted, or overwritten, plus focused
  catalog/reader tests to guard the kubectl call surfaces.
- Spec dilution detection: The plan deliberately narrows support to inherited
  `KUBECONFIG` and records the App Settings path-list question as deferred
  rather than silently dropping it. The core requirement, colon-delimited
  multi-file support through `kubectl`, remains covered.

## Scope Boundaries

- In scope: preserving inherited `KUBECONFIG`, tests around command launch
  environment and kubectl-backed service boundaries, and runtime documentation.
- Out of scope: App Settings UI for kubeconfig files, persisted kubeconfig
  paths, custom YAML merging, current-context mutation, HealthEvaluator rules,
  watchlist schema changes, and Kubernetes Secrets reads.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Kubectl-backed reads preserve colon-delimited KUBECONFIG.
- Verification: swift test --filter CommandRunnerTests && swift test --filter ContextCatalogTests && swift test --filter WatchTargetCatalogTests && swift test --filter KubectlClusterReaderTests && rtk git diff --check
- Depends on: None
- Test scenarios: command launch environment preserves `/tmp/a:/tmp/b` as one KUBECONFIG value; PATH normalization still works; context discovery still uses `kubectl config get-contexts`; cluster refresh still passes explicit app-owned `--context`; setup candidate discovery still uses the command runner boundary

**Goal:** Make the multi-file kubeconfig contract explicit and test-covered at
Kubebar's command boundary.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R1-R6

**Dependencies:** None

**Discovery cache:**
- `KubebarCore/Services/CommandRunner.swift` (process launch environment)
- `KubebarCore/Services/ContextCatalog.swift` (context discovery command)
- `KubebarCore/Services/WatchTargetCatalog.swift` (watch target discovery command)
- `KubebarCore/Services/KubectlClusterReader.swift` (cluster refresh commands)
- `KubebarTests/Services/CommandRunnerTests.swift` (environment tests)
- `KubebarTests/Services/ContextCatalogTests.swift` (context discovery tests)
- `KubebarTests/Services/WatchTargetCatalogTests.swift` (candidate discovery tests)
- `KubebarTests/Services/KubectlClusterReaderTests.swift` (refresh command tests)
- `docs/architecture/runtime-invariants.md` (runtime config rules)

**Files:**
- Modify: `KubebarTests/Services/CommandRunnerTests.swift`
- Modify: `KubebarTests/Services/ContextCatalogTests.swift`
- Modify: `KubebarTests/Services/WatchTargetCatalogTests.swift`
- Modify: `KubebarTests/Services/KubectlClusterReaderTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Reference: `KubebarCore/Services/CommandRunner.swift`
- Reference: `KubebarCore/Services/ContextCatalog.swift`
- Reference: `KubebarCore/Services/WatchTargetCatalog.swift`
- Reference: `KubebarCore/Services/KubectlClusterReader.swift`

**Approach:**
- Start with a focused failing test proving a colon-delimited `KUBECONFIG`
  value survives `ProcessCommandRunner.launchEnvironment`.
- Confirm `PATH` behavior remains unchanged and no code normalizes
  `KUBECONFIG`.
- Add or adjust focused catalog/reader tests only where needed to make the
  kubectl command boundary explicit.
- Make the minimal production change if tests expose a gap.
- Update runtime invariants to state that Kubebar delegates multi-file
  kubeconfig merging to `kubectl` and preserves inherited `KUBECONFIG`.
- Run focused tests and diff hygiene, then run the full Swift quality gate if
  practical.

**Verification:**
- Focused:
  - `swift test --filter CommandRunnerTests`
  - `swift test --filter ContextCatalogTests`
  - `swift test --filter WatchTargetCatalogTests`
  - `swift test --filter KubectlClusterReaderTests`
  - `rtk git diff --check`
- Preferred full gate:
  - `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`

**failure_behavior:** If focused tests prove inherited `KUBECONFIG` cannot be
observed reliably for GUI-launched app flows, stop and replan the deferred App
Settings kubeconfig path-list slice instead of hiding the gap.

**security_considerations:** Do not log or display kubeconfig paths, merged
config contents, tokens, command transcripts, or Kubernetes Secrets. Failure
messages must continue using safe summaries.
