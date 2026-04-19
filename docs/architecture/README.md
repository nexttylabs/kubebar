# Architecture Notes

Use this directory for Kubebar architecture notes that are too detailed for the
repo-wide quick-start guide.

Current notes:

- `system-overview.md` — major subsystems and request flow
- `runtime-invariants.md` — defaults and guarantees that must not break

Future notes can be added here when a subsystem needs more detail:

- `module-map.md` — ownership boundaries by directory or target
- `integrations.md` — external services, auth, webhooks, queues, and data flows

Keep `AGENTS.md` as the short operational contract. Put longer explanations and subsystem-specific rules here.
