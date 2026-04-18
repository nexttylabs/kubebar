---
name: ship
version: 1.0.0
description: Use when the user wants the project's defined quality gate run before shipping, releasing, committing, or opening a pull request.
activation:
  patterns:
    - "ready.*to ship"
    - "run.*quality gate"
    - "quality gate"
  keywords:
    - release
    - ship
    - verify
  max_context_tokens: 1200
---

# Ship

Read the quality gate in `AGENTS.md` and run each step in order. Report the result and stop on the first failure.

If `AGENTS.md` does not define the commands needed to verify the project, ask the user what should be run.

## Output Format

- Commands run
- First failing step, if any
- Final pass/fail status
