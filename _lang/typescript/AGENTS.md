# {{PROJECT_NAME}} TypeScript Guide

## Purpose and Precedence

- `AGENTS.md` is the repo-wide quick-start contract for contributors and coding agents.
- If a deeper guide exists in a subdirectory or under `docs/architecture/`, treat that guide as authoritative for that area.
- Keep this file current when project structure, quality gates, or ownership boundaries change.

## Architecture Mental Model

- Keep entry points and app wiring thin; move module-owned logic into the module that owns it.
- Keep domain logic separate from transport, storage, and external service adapters.
- Extend existing types, factories, registries, and policy layers before adding one-off paths.

## Where to Work

- Application logic: `src/`
- Shared or internal packages: `lib/`
- Tests: `tests/`
- Tooling and automation: `scripts/`
- Architecture notes and longer specs: `docs/`

## Build & Quality Gate

```bash
pnpm format:check
pnpm lint
pnpm typecheck
pnpm test
```

Use `pnpm build` before shipping when the project exposes a build step.

## Coding Rules

- Enable strict TypeScript settings and keep them strict
- No `any` types — use `unknown` and narrow with type guards
- No `as` casts unless a nearby comment explains why they are safe
- No `@ts-ignore` without an adjacent comment explaining why it is unavoidable
- No `var` — use `const` by default, `let` only when reassignment is necessary
- No floating promises — every async call must be `await`ed, returned, or explicitly voided
- Catch blocks must type the error as `unknown` and narrow before accessing properties
- No non-null assertions (`!`) without a comment justifying safety
- Prefer `readonly` for arrays and objects that should not be mutated
- Use discriminated unions and exhaustive switches with `never` defaults
- Named exports only — no default exports
- Import order: node builtins → external packages → internal modules → relative imports

## Project Structure

```text
src/      Application source
lib/      Shared library code or internal packages
tests/    Unit, integration, and end-to-end tests
scripts/  Build, migration, and utility scripts
```

## Dependencies

```bash
pnpm add <package>
pnpm add -D <package>
```

- Commit `pnpm-lock.yaml`
- Pin major versions for critical dependencies

## Change Discipline

- If behavior changes, update the relevant docs, specs, README, API references, or changelog in the same branch.
- Preserve existing defaults unless the task explicitly changes them.
- Treat auth, secrets, config loading, persistence, migrations, CI, and public or network-facing APIs as high-risk changes. Call out compatibility and rollback risk when they move.

## Before Finishing

Run and confirm all pass with zero warnings:

```bash
pnpm format:check
pnpm lint
pnpm typecheck
pnpm test
```

Also confirm whether the change requires updates in `docs/`, `README.md`, or `CHANGELOG.md`.

If any command fails, fix the issue before marking the task complete. Do not suppress warnings with `@ts-ignore` or `eslint-disable` unless the suppression itself is the agreed-upon fix.
