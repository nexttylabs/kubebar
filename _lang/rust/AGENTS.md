# {{PROJECT_NAME}} Rust Guide

## Purpose and Precedence

- `AGENTS.md` is the repo-wide quick-start contract for contributors and coding agents.
- If a deeper guide exists in a subdirectory or under `docs/architecture/`, treat that guide as authoritative for that area.
- Keep this file current when project structure, quality gates, or ownership boundaries change.

## Architecture Mental Model

- Keep `main.rs`, `lib.rs`, and top-level app wiring thin; move module-owned logic into the module that owns it.
- Keep domain logic separate from transport, persistence, and external service adapters.
- Extend existing traits, factories, and registries before adding one-off integration paths.

## Where to Work

- Runtime and library code: `src/`
- Workspace crates: `crates/`
- Integration tests: `tests/`
- Tooling and automation: `scripts/`
- Architecture notes and longer specs: `docs/`

## Build & Quality Gate

```bash
cargo fmt
cargo clippy --all --benches --tests --examples --all-features
cargo test
```

All three commands must pass cleanly before code is ready.

## Coding Rules

- Never use `.unwrap()` or `.expect()` in production code. Tests may use them.
- Keep clippy clean: zero warnings, no `#[allow]` suppression without a justifying comment.
- Prefer `crate::` imports for internal modules.
- Use strong types and enums over raw strings or integers. Wrap domain identifiers in newtypes.
- Define error types with `thiserror`; propagate with `?` and add context via `.context()`.
- Keep items private by default. Use `pub(crate)` before `pub`.
- Every `match` on an enum must be exhaustive — no wildcard `_` arms unless the enum is explicitly non-exhaustive.

## Project Structure

```text
src/        Binary or library source
crates/     Workspace member crates
tests/      Integration tests
benches/    Benchmarks
migrations/ Database migrations when applicable
```

## Rust-Specific Invariants

- New dependencies should pass `cargo deny check` before merge.
- Keep `panic!`, `assert!`, `.unwrap()`, and `.expect()` out of changed production code.
- If behavior changes, update the relevant docs, specs, README, or changelog in the same branch.
- Preserve existing defaults unless the task explicitly changes them.
- Treat auth, secrets, config loading, persistence, migrations, CI, and public or network-facing APIs as high-risk changes. Call out compatibility and rollback risk when they move.

## Before Finishing

Run these checks and confirm all pass before declaring work complete:

```bash
cargo fmt
cargo clippy --all --benches --tests --examples --all-features
cargo test
cargo deny check
```

Additionally:
- Grep changed `*.rs` files for `.unwrap()` and `.expect()` — none allowed outside `#[cfg(test)]` modules.
- Confirm any new public API has doc comments.
- Confirm any new error variants are covered by a test.
- Confirm whether the change requires updates in `docs/`, `README.md`, or `CHANGELOG.md`.
