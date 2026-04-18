---
name: plan-mode
version: 0.1.0
description: Use when a task needs a written execution plan with explicit steps, risks, verification, and user approval before implementation starts.
activation:
  keywords:
    - "[PLAN MODE]"
    - plan mode
    - create a plan
  patterns:
    - "enter.*plan.*mode"
    - "make.*a.*plan"
    - "plan.*this"
    - "write.*plan"
  tags:
    - planning
    - autonomous
    - task-management
  max_context_tokens: 2500
---

# Plan Mode

A structured lifecycle for breaking complex work into verifiable steps, writing them to a plan document, and executing them autonomously.

## 1. Creating a Plan

### Gather context

Before writing anything, collect the information needed to plan well:

- Read relevant files, configs, and documentation.
- Identify constraints (time, risk, dependencies, available tools).
- Clarify ambiguous requirements with the user.

### Analyze

- Determine the minimal set of changes required.
- Identify independent vs. sequential steps.
- Flag anything that needs user approval before proceeding.

### Write the plan

Create a file at `plans/<slug>.md` using the format below. The slug should be a short, lowercase, hyphenated description (e.g., `add-retry-logic`).

### Emit checklist

After writing the plan file, print a numbered checklist summary so the user can review and approve it.

## 2. Plan Document Format

```markdown
# Plan: <title>

plan_id: <slug>
status: draft | approved | in_progress | blocked | completed | abandoned
current_focus: <step number or none>

## Goal

One or two sentences describing the desired outcome.

## Success Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Steps

### Step 1 — <short description>

- **Tools**: <which tools or commands this step uses>
- **Risk**: low | medium | high
- **Estimate**: <time or effort estimate>
- **Details**: What to do and what "done" looks like.

### Step 2 — ...

## Risks

- Risk description → mitigation strategy.

## Progress Log

| Step | Status      | Notes |
|------|-------------|-------|
| 1    | pending     |       |
| 2    | pending     |       |
```

## 3. Plan Rules

1. Each step must specify the **tools** it will use.
2. Each step must be **independently verifiable** — there should be a concrete way to confirm it succeeded.
3. Each step must include a **risk assessment** (low / medium / high).
4. Each step must include a **time estimate**.
5. A plan may have at most **20 steps**. If more are needed, split into multiple plans.
6. Steps should be ordered so that failures are caught early (high-risk or validation steps first when possible).

## 4. Approving and Executing

### Approve

The plan stays in `draft` status until the user explicitly approves it. Do not begin execution on a draft plan.

### Execute

1. Read the plan file to determine the current state.
2. Set plan status to `in_progress`.
3. Update `current_focus` to the step you are actively working on.
4. For each step marked `pending`:
   - Check `current_focus` — only work on one step at a time.
   - Execute the step using the specified tools.
   - Verify the result.
   - Update the Progress Log: set status to `done`, `failed`, or `skipped`, and add notes.
5. When all steps are resolved, set the plan status to `completed` and `current_focus` to `none`.

### Handle failures

- If a step fails, update its status to `failed` with a description of what went wrong.
- Attempt the step once more if the failure seems transient.
- If it fails again, set the plan status to `blocked` and report to the user. Do not skip ahead to later steps that depend on the failed one.

## 5. Checking Status

Re-read the plan file and print the Progress Log table. Highlight any steps that are `failed` or `blocked`.

## 6. Listing Plans

List all files in the `plans/` directory and print their `plan_id` and `status`.

## 7. Revising Plans

If requirements change mid-execution:

1. Set the plan status to `draft`.
2. Update the Goal, Steps, and Risks as needed.
3. Reset any not-yet-started steps to `pending`.
4. Set `current_focus` to `none`.
5. Get user approval again before resuming execution.
