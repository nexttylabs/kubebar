---
paths:
  - "**/*.swift"
  - "Tests/**"
  - "UITests/**"
---

# Swift Testing Rules

## Test Tiers

| Tier | Command | Scope |
|---|---|---|
| Unit | `swift test` or `xcodebuild test` | Models, reducers, services, formatters |
| Integration | `xcodebuild test` | Module boundaries, persistence, networking adapters |
| UI | `xcodebuild test` with UI test target | End-to-end user flows and critical screen states |

## Structure

- Keep unit tests under `Tests/`
- Keep UI tests under `UITests/`
- Mirror feature names between source and tests when possible
- Prefer descriptive `test_` method names that describe behavior, not implementation

## Mocking

- Mock at external boundaries such as networking, persistence, and clock/time
- Prefer lightweight fakes over global stubs
- Do not mock the type under test

## Assertions

- One behavior per test
- Assert user-visible outputs, state transitions, and emitted actions
- When testing async code, assert cancellation and failure paths as well as success

## Snapshots

- Snapshot tests are optional
- Use them for stable visual states, not for rapidly changing layouts or animation frames
- Keep snapshot fixtures small and reviewable
