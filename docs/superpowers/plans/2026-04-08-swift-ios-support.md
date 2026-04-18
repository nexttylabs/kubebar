# Swift iOS Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Swift iOS support to the project template with setup, docs, hooks, CI, and reusable quality checks.

**Architecture:** Extend the existing overlay-based language system rather than inventing a new integration path. Keep Swift-specific build and test logic in a shared helper script so local hooks and CI use the same behavior.

**Tech Stack:** Bash, GitHub Actions, Xcode, xcodebuild, swift

---

### Task 1: Add a failing verification script

**Files:**
- Create: `tests/swift_template_support.sh`

- [ ] **Step 1: Write the failing test**

```bash
printf 'Demo App\n5\n1\n' | ./init.sh
test -f AGENTS.md
grep -q "Swift Guide" AGENTS.md
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/swift_template_support.sh`
Expected: fail because `init.sh` does not yet accept Swift.

- [ ] **Step 3: Keep the script as the regression check**

```bash
PATH="$TMP_DIR/bin:$PATH" ./scripts/dev-setup.sh --check-only
PATH="$TMP_DIR/bin:$PATH" ./scripts/swift-quality-gate.sh local
```

- [ ] **Step 4: Re-run after implementation**

Run: `bash tests/swift_template_support.sh`
Expected: PASS

### Task 2: Add the Swift overlay

**Files:**
- Create: `_lang/swift/.gitignore`
- Create: `_lang/swift/AGENTS.md`
- Create: `_lang/swift/ci.yml`
- Create: `_lang/swift/commit-msg.partial`
- Create: `_lang/swift/labeler.yml`
- Create: `_lang/swift/pre-push.partial`
- Create: `_lang/swift/review-discipline.md`
- Create: `_lang/swift/ship.md`
- Create: `_lang/swift/testing.md`
- Create: `_lang/swift/scripts/swift-quality-gate.sh`

- [ ] **Step 1: Add Swift project guidance**
- [ ] **Step 2: Add local and CI quality gate definitions**
- [ ] **Step 3: Add regression-test detection patterns**
- [ ] **Step 4: Add iOS-specific ignore rules**

### Task 3: Wire Swift into setup and detection

**Files:**
- Modify: `init.sh`
- Modify: `scripts/dev-setup.sh`

- [ ] **Step 1: Add `swift` to the interactive language selector**
- [ ] **Step 2: Copy optional overlay scripts during initialization**
- [ ] **Step 3: Detect Swift projects from Xcode or Swift package markers**
- [ ] **Step 4: Require `swift` and `xcodebuild` for Swift setup checks**

### Task 4: Update template documentation

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add Swift to supported languages**
- [ ] **Step 2: Update quick-start instructions**
- [ ] **Step 3: Document Swift quality gate and CI behavior**

### Task 5: Validate and polish

**Files:**
- Modify: `tests/swift_template_support.sh` if verification gaps appear

- [ ] **Step 1: Run `bash tests/swift_template_support.sh`**
- [ ] **Step 2: Review generated files for missing references to supported languages**
- [ ] **Step 3: Fix any mismatches and re-run verification**

## Self-Review

- Spec coverage: overlay, setup, quality gate, CI, docs, and regression-test detection are all mapped to tasks.
- Placeholder scan: no `TODO` or deferred work remains in the plan.
- Type consistency: environment variable names and Swift script names are consistent across tasks.
