# IMMUNE.md - Immune-Brain Constitution

This project uses the Immune-Brain workflow.

## Core Principles

- Files are the durable memory for important decisions and workflow state.
- Plan before code. Create or update a spec before changing core behavior.
- Work in small, independently verifiable steps.
- Keep changes scoped to the current goal.

## Workflow Order

1. `imm-brainstorm` clarifies the request and boundaries.
2. `imm-preplan-review` is optional when scope or closure needs one more pass.
3. `imm-planner` creates the spec and plan.
4. `imm-work` drives one active step at a time through execution and QA.
5. `imm-compounder` records reusable learnings after the task closes.

## Project Artifacts

- `.imm/memory/` stores durable workflow memory.
- `.imm/specs/` stores task specs.
- `docs/brainstorms/` stores clarified request framing.
- `docs/plans/` stores validated execution plans.
