---
description: Run the TypeScript quality gate (format, lint, typecheck, test, build) before shipping.
allowed-tools:
  - Bash(pnpm:*)
---

# Ship

Run the TypeScript quality gate. Stop on the first failure and fix it before continuing.

1. **Format**: `pnpm format:check`
2. **Lint**: `pnpm lint`
3. **Typecheck**: `pnpm typecheck`
4. **Test**: `pnpm test`
5. **Build**: `pnpm build`

All five steps must pass with zero warnings before committing or opening a PR.
