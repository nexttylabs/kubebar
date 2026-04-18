---
paths:
  - "src/**/*.rs"
---

# Rust Review Discipline

## Fix the Pattern, Not the Instance

When a review finds a bug, search the entire codebase for the same pattern. If it appears in trait implementations, fix every impl — not just the one that was caught.

## Propagate to All Trait Implementations

When changing a trait method signature, default implementation, or documented contract, update every `impl` block for that trait. Grep for `impl YourTrait for` and verify each one.

## Feature Flag Testing

When the crate uses feature flags, verify the change compiles under all relevant combinations:

```bash
cargo check --no-default-features
cargo check --all-features
cargo check --features "feature-a"
cargo check --features "feature-b"
```

## Regression Test with Every Fix

Every bug fix must include a test that fails without the fix and passes with it. No exceptions.

## Zero Clippy Warnings

`cargo clippy` must produce zero warnings. Do not add `#[allow(clippy::...)]` without a comment explaining why the lint is wrong for that specific case.

## No Byte-Index Slicing on User Strings

Never slice a `&str` by byte index (`&s[start..end]`) on user-provided or externally-sourced strings. Use `.chars()`, `.char_indices()`, or the `unicode-segmentation` crate. Byte slicing panics on multi-byte UTF-8 boundaries.

## Decorator / Wrapper Trait Delegation

When wrapping a type that implements a trait, delegate all trait methods — not just the ones you need today. Missing delegations cause silent behavior changes when the inner type's implementation evolves.

## Mechanical Verification Checklist

Before approving a Rust PR, verify:

- [ ] `cargo fmt --check` produces no diff
- [ ] `cargo clippy --all --benches --tests --examples --all-features` produces zero warnings
- [ ] `cargo test` passes
- [ ] No `.unwrap()` or `.expect()` in non-test code
- [ ] New public items have doc comments
- [ ] Error types use `thiserror` and include context
- [ ] No `todo!()` or `unimplemented!()` in shipped code
- [ ] Feature flag combinations compile (`--no-default-features`, `--all-features`)
