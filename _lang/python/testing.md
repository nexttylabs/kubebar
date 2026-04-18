---
paths:
  - "src/**/*.py"
  - "tests/**/*.py"
  - "**/test_*.py"
  - "**/*_test.py"
---

# Python Testing Rules

## Test Tiers

| Tier        | Command                     | Scope                                  |
|-------------|-----------------------------|----------------------------------------|
| Unit        | `pytest`                    | Pure functions, isolated modules       |
| Integration | `pytest -m integration`     | Module boundaries, APIs, DB access     |
| E2E         | `pytest -m e2e`             | Full user flows through the system     |

## Structure

- Mirror `src/<package>/` layout inside `tests/` — e.g. `src/myapp/auth.py` → `tests/unit/test_auth.py`
- `test_` prefix for test functions, `Test` prefix for test classes
- Use `conftest.py` for shared fixtures — place at the appropriate directory level
- Group related tests in classes when they share setup, otherwise use standalone functions

## Fixtures

- Use `@pytest.fixture` for setup and teardown — prefer over manual setup in test bodies
- Use `tmp_path` fixture for temporary directories — never hardcode paths
- Use `monkeypatch` for patching environment variables, attributes, and dict items
- Scope fixtures appropriately: `function` (default) for isolation, `session` for expensive shared resources
- Clean up resources in fixture teardown (`yield` pattern) — don't rely on garbage collection

## Mocking

- Use `monkeypatch` or `unittest.mock.patch` — mock at the boundary (HTTP, DB, filesystem)
- Prefer dependency injection over module-level patching
- Use `responses` or `httpx_mock` for HTTP mocking — avoid mocking internal functions

## Parametrize

- Use `@pytest.mark.parametrize` for table-driven tests — test multiple inputs with one function
- Name parametrize IDs clearly: `@pytest.mark.parametrize("input,expected", [...], ids=[...])`

## Assertions

- Use plain `assert` statements — pytest introspection provides clear failure messages
- Assert error types with `pytest.raises(SpecificError)` — check the message when it matters
- One logical assertion per test — split multi-facet checks into separate tests

## Coverage

- Do not chase 100% coverage — cover business logic, edge cases, and error paths
- Untested code should have a comment explaining why (e.g. platform-specific, CLI-only)
