# Phase 08: Prepare Local macOS Distribution - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution
> agents. Decisions are captured in `08-CONTEXT.md`; this log preserves the
> alternatives considered.

**Date:** 2026-04-22
**Phase:** 08-prepare-local-macos-distribution
**Source issue:** https://github.com/nexttylabs/kubebar/issues/8
**Areas discussed:** distribution shape, signing boundary, install docs,
verification

---

## Distribution Shape

| Option | Description | Selected |
| --- | --- | --- |
| Copied app bundle | Build `Kubebar.app`, then copy it into a user-owned Applications directory. | yes |
| Signed local build | Require local signing identity or team setup before install. | no |
| Package artifact | Produce pkg, dmg, Homebrew, or release artifact. | no |

**Decision:** Use a copied macOS `.app` bundle as the first local distribution
shape.

**Notes:** This matches issue #8's local-install goal while preserving the
explicit boundary against notarization, Homebrew, and public release automation.

---

## Signing Boundary

| Option | Description | Selected |
| --- | --- | --- |
| No Developer ID requirement | Keep local install usable without Apple developer certificate setup. | yes |
| Ad-hoc signing only if needed | Allow local signing only to make the copied bundle launch reliably. | yes |
| Public release signing | Prepare Developer ID signing and notarization. | no |

**Decision:** Do not require Developer ID signing or notarization. Local or
ad-hoc signing may be used only if required for local launchability.

**Notes:** `project.yml` remains the source of truth for durable app target
settings.

---

## Install Documentation

| Option | Description | Selected |
| --- | --- | --- |
| README install section | Extend current build/run docs with install, update, uninstall, and reset steps. | yes |
| Separate release guide | Create a broader public distribution guide. | no |
| Script-only behavior | Rely on script output without durable docs. | no |

**Decision:** Add durable local install documentation near the existing README
build/test/run instructions.

**Notes:** Docs must clearly separate app uninstall from config reset and state
that Kubebar does not store Kubernetes credentials.

---

## Verification

| Option | Description | Selected |
| --- | --- | --- |
| Quality gate plus bundle proof | Run the existing quality gate and verify the produced `.app` metadata/assets. | yes |
| Build-only proof | Treat a successful build as enough. | no |
| New UI automation stack | Add new automation for visible menu inspection. | no |

**Decision:** Require the existing local quality gate before install, plus
bundle-level proof that the copied app is a real Kubebar app bundle.

**Notes:** `./scripts/compile-and-run.sh` remains the visible-app smoke path;
this phase should not introduce a new UI automation surface.

---

## the agent's Discretion

- Exact script names and flags.
- Whether install and uninstall are implemented as scripts or documented shell
  commands.
- Whether the installer relaunches Kubebar by default or exposes relaunch as a
  flag.
- Exact bundle metadata checks, provided they prove the installed `.app` is the
  expected Kubebar menu bar app.

## Deferred Ideas

- Developer ID signing.
- Notarization.
- Homebrew.
- Sparkle.
- pkg or dmg packaging.
- GitHub release automation.
- Public release documentation.
- Deeper-debugging handoff such as `Open in k9s`.
