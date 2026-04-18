---
description: Run the Rust quality gate (fmt, clippy, test) before shipping.
allowed-tools:
  - Bash(cargo:*)
---

# Ship

Run the Rust quality gate. Stop on the first failure and fix it before continuing.

1. **Format**: `cargo fmt`
2. **Lint** (must produce zero warnings): `cargo clippy --all --benches --tests --examples --all-features`
3. **Test**: `cargo test --lib`

All three steps must pass cleanly. If any step fails, fix the issue and restart from step 1.
