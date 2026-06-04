---
title: KUBECONFIG Multi-File Support
date: 2026-06-04
status: planned
origin: user request for Linux/macOS colon-delimited KUBECONFIG support
---

# KUBECONFIG Multi-File Support

## Summary

Kubebar should support Linux/macOS `KUBECONFIG` values that contain multiple
files separated by `:`. Kubebar should not parse or merge kubeconfig YAML
itself. It should preserve the inherited `KUBECONFIG` environment value and let
`kubectl` perform its normal merged-config behavior.

This keeps Kubebar aligned with the existing app-owned context model: Kubebar
chooses an explicit saved context, while `kubectl` resolves that context from
the effective local kubeconfig set.

## Goals

- Preserve an inherited colon-delimited `KUBECONFIG` value for every
  `kubectl` process Kubebar launches.
- Keep context discovery, watch target discovery, and cluster refreshes on the
  same `kubectl` command boundary.
- Continue passing the app-owned selected context explicitly with `--context`
  for cluster reads.
- Add tests that catch accidental splitting, truncation, replacement, or
  omission of `KUBECONFIG`.
- Document that Kubebar delegates kubeconfig merge behavior to `kubectl`.

## Non-Goals

- No in-app kubeconfig file picker or stored kubeconfig path list in this
  executable slice.
- No custom kubeconfig YAML parser or merger.
- No changes to `kubectl config use-context`.
- No reliance on the terminal's current Kubernetes context.
- No Kubernetes Secrets reads.
- No Windows path-list delimiter support.

## Requirements

- R1. `ProcessCommandRunner` must preserve `KUBECONFIG` exactly when building a
  process launch environment, including values such as `/tmp/a:/tmp/b`.
- R2. PATH normalization must remain scoped to `PATH`; it must not normalize or
  split `KUBECONFIG`.
- R3. `ContextCatalog`, `WatchTargetCatalog`, and `KubectlClusterReader` must
  continue to run through the injectable `CommandRunning` boundary.
- R4. Kubebar must let `kubectl` merge kubeconfig files; Kubebar must not add
  its own merge logic.
- R5. Cluster reads must continue using the app-owned selected context with
  explicit `--context`.
- R6. Failure display must remain safe and must not show raw kubeconfig
  contents, tokens, or command transcripts.

## Verification Expectations

- Focused command-runner tests prove colon-delimited `KUBECONFIG` is preserved
  while PATH search paths are still normalized.
- Existing catalog and reader tests prove kubectl commands still use the
  command boundary and explicit context arguments.
- Documentation or runtime invariants record that multiple kubeconfig files are
  delegated to `kubectl`.
- Preferred full verification remains `./scripts/swift-quality-gate.sh local`
  after the focused tests pass.
