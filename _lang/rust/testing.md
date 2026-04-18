---
paths:
  - "src/**/*.rs"
  - "tests/**"
---

# Rust Testing Rules

## Test Tiers

| Tier | Command | Scope |
|------|---------|-------|
| Unit | `cargo test` | `#[cfg(test)] mod tests` inside source files |
| Integration | `cargo test --features integration` | `tests/` directory, full binary / service tests |

## Patterns

### Unit Tests

Place unit tests in a `mod tests` block at the bottom of the file they test:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_valid_input() {
        let result = parse("valid");
        assert_eq!(result, expected);
    }
}
```

### Async Tests

Use `#[tokio::test]` for async test functions:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn fetches_resource() {
        let result = fetch("https://example.com").await;
        assert!(result.is_ok());
    }
}
```

### No Mocks — Prefer Real Implementations

Avoid mock frameworks. Prefer:

- Real implementations behind trait objects or generics
- In-memory implementations of storage traits (e.g., `HashMap`-backed store)
- `tempfile` crate for filesystem tests
- Test fixtures loaded from `tests/fixtures/`

### Temporary Files

Use the `tempfile` crate for tests that need filesystem access:

```rust
use tempfile::TempDir;

#[test]
fn writes_output_file() {
    let dir = TempDir::new().unwrap();
    let path = dir.path().join("output.txt");
    write_output(&path).unwrap();
    assert!(path.exists());
}
```

### Error Case Testing

Test both success and failure paths. Use `assert!(result.is_err())` or match on specific error variants:

```rust
#[test]
fn rejects_empty_input() {
    let result = parse("");
    assert!(matches!(result, Err(ParseError::EmptyInput)));
}
```

## Rules

- Every bug fix must include a regression test.
- `.unwrap()` and `.expect()` are allowed in tests.
- Test names describe the behavior, not the implementation: `rejects_empty_input` over `test_parse_3`.
- Keep test setup minimal. If multiple tests share setup, extract a helper function — not a macro.
