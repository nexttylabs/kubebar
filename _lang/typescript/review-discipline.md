---
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
---

# TypeScript Review Discipline

## Type Safety

- No `any` types — use `unknown` and narrow with type guards or assertion functions
- No `@ts-ignore` or `@ts-expect-error` without an adjacent comment explaining why
- No non-null assertions (`!`) without a comment justifying why the value is guaranteed
- Catch blocks must type the error as `unknown` — never assume `Error`

## Async Safety

- No floating promises — every async call must be `await`ed, returned, or explicitly voided
- No `async` functions that silently swallow errors — always propagate or handle

## Null Safety

- Prefer optional chaining (`?.`) and nullish coalescing (`??`) over manual checks
- No unchecked `.value!` or `as SomeType` to bypass nullability — narrow first

## Imports & Exports

- Import order: node builtins → external packages → internal aliases → relative paths
- Barrel exports (`index.ts`) must re-export explicitly — no `export *`
- Named exports only — no default exports

## Testing

- Every bug fix must include a regression test that fails without the fix
- Tests must not depend on execution order

## Lint Policy

- Zero lint warnings — treat warnings as errors
- No `eslint-disable` without an adjacent comment and a tracking issue
