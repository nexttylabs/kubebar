---
paths:
  - "src/**/*.ts"
  - "tests/**"
  - "**/*.test.ts"
  - "**/*.spec.ts"
---

# TypeScript Testing Rules

## Test Tiers

| Tier        | Command                  | Scope                                  |
|-------------|--------------------------|----------------------------------------|
| Unit        | `pnpm test`              | Pure functions, isolated modules       |
| Integration | `pnpm test:integration`  | Module boundaries, API routes, DB      |
| E2E         | `pnpm test:e2e`          | Full user flows through the system     |

## Structure

- Mirror `src/` layout inside `tests/` — e.g. `src/auth/login.ts` → `tests/unit/auth/login.test.ts`
- Use `describe`/`it` blocks with clear, behavior-oriented names
- Use `beforeEach`/`afterEach` for setup and teardown — avoid `beforeAll` unless expensive setup is truly shared

## Mocking

- Use `vi.mock()` or `jest.mock()` sparingly — prefer dependency injection over module-level mocks
- Mock at the boundary (HTTP, DB, filesystem), not internal functions
- Restore all mocks in `afterEach` to avoid cross-test pollution

## File System

- Use temporary directories (`fs.mkdtempSync` or a `tmp` helper) — never hardcode paths
- Clean up temp files in `afterEach` or `afterAll`

## Assertions

- One logical assertion per `it` block — if testing multiple facets, use separate `it` blocks
- Prefer strict equality (`toBe`, `toStrictEqual`) over loose matchers
- Assert error types explicitly: `expect(() => fn()).toThrow(SpecificError)`

## Coverage

- Do not chase 100% coverage — cover business logic, edge cases, and error paths
- Untested code should have a comment explaining why (e.g. platform-specific, visual-only)
