#!/usr/bin/env bash
# Project template initialization script.
# Merges language-specific overlays into the template and configures dev tools.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LANG_DIR="$SCRIPT_DIR/_lang"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}==>${NC} $1"; }
ok()    { echo -e "${GREEN}==>${NC} $1"; }
warn()  { echo -e "${YELLOW}==>${NC} $1"; }
error() { echo -e "${RED}==>${NC} $1"; }

# --- Check prerequisites ---
if [ ! -d "$LANG_DIR" ]; then
  error "No _lang/ directory found. Has init.sh already been run?"
  exit 1
fi

# --- Prompt: Project name ---
echo ""
echo -e "${BLUE}AI-Native Project Template Setup${NC}"
echo "=================================="
echo ""

read -rp "Project name: " PROJECT_NAME
if [ -z "$PROJECT_NAME" ]; then
  error "Project name is required."
  exit 1
fi

# --- Prompt: Language ---
echo ""
echo "Available languages:"
echo "  1) rust"
echo "  2) typescript"
echo "  3) golang"
echo "  4) python"
echo "  5) swift"
echo ""
read -rp "Primary language [1-5]: " LANG_CHOICE

case "$LANG_CHOICE" in
  1|rust)       LANG="rust";;
  2|typescript) LANG="typescript";;
  3|golang)     LANG="golang";;
  4|python)     LANG="python";;
  5|swift)      LANG="swift";;
  *)
    error "Invalid language choice: $LANG_CHOICE"
    exit 1
    ;;
esac

if [ ! -d "$LANG_DIR/$LANG" ]; then
  error "Language overlay not found: $LANG_DIR/$LANG"
  exit 1
fi

# --- Prompt: Dev tools ---
echo ""
echo "Dev tools to configure:"
echo "  1) codex  - Codex-first setup with AGENTS.md + skills/  [default]"
echo "  2) both   - Codex-first setup + Cursor (.cursor/) rules"
echo "  3) cursor - Cursor (.cursor/) rules"
echo ""
read -rp "Dev tools [1-3, default=1]: " TOOLS_CHOICE

case "${TOOLS_CHOICE:-1}" in
  1|codex)  TOOLS="codex";;
  2|both)   TOOLS="both";;
  3|cursor) TOOLS="cursor";;
  *)
    error "Invalid tools choice: $TOOLS_CHOICE"
    exit 1
    ;;
esac

echo ""
info "Configuring for: $PROJECT_NAME ($LANG) with $TOOLS tooling"
echo ""

# --- Copy language overlay files ---
OVERLAY="$LANG_DIR/$LANG"

info "Copying AGENTS.md..."
cp "$OVERLAY/AGENTS.md" "$SCRIPT_DIR/AGENTS.md"

info "Copying .gitignore..."
cp "$OVERLAY/.gitignore" "$SCRIPT_DIR/.gitignore"

info "Copying CI workflow..."
cp "$OVERLAY/ci.yml" "$SCRIPT_DIR/.github/workflows/ci.yml"

info "Copying labeler config..."
cp "$OVERLAY/labeler.yml" "$SCRIPT_DIR/.github/labeler.yml"

if [ -f "$OVERLAY/deny.toml" ]; then
  info "Copying deny.toml..."
  cp "$OVERLAY/deny.toml" "$SCRIPT_DIR/deny.toml"
fi

# --- Ship skill (language-specific) ---
mkdir -p "$SCRIPT_DIR/skills/ship"

info "Copying ship skill..."
cp "$OVERLAY/ship.md" "$SCRIPT_DIR/skills/ship/SKILL.md"

if [ -d "$OVERLAY/scripts" ]; then
  info "Copying overlay scripts..."
  mkdir -p "$SCRIPT_DIR/scripts"
  cp -R "$OVERLAY/scripts/." "$SCRIPT_DIR/scripts/"
fi

# --- Build regression-test-check workflow from partial ---
info "Generating regression-test-check workflow..."
cat > "$SCRIPT_DIR/.github/workflows/regression-test-check.yml" << 'WORKFLOW_HEADER'
name: Regression Test Check

on:
  pull_request:

jobs:
  regression-test:
    name: Regression test enforcement
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check for regression tests
        env:
          PR_TITLE: ${{ github.event.pull_request.title }}
          PR_LABELS: ${{ join(github.event.pull_request.labels.*.name, ',') }}
        run: |
          set -euo pipefail
          BASE_REF="origin/${{ github.event.pull_request.base.ref }}"
          HEAD_REF="${{ github.event.pull_request.head.sha }}"

          # Is this a fix PR?
          IS_FIX=false
          if grep -qiE '^(fix(\(.*\))?|hotfix|bugfix):' <<< "$PR_TITLE"; then
            IS_FIX=true
          fi
          if [ "$IS_FIX" = false ]; then
            echo "Not a fix PR -- skipping."
            exit 0
          fi

          # Skip label
          if grep -qF ',skip-regression-check,' <<< ",$PR_LABELS,"; then
            echo "skip-regression-check label present -- skipping."
            exit 0
          fi

          CHANGED_FILES=$(git diff --name-only "${BASE_REF}...${HEAD_REF}")
          if [ -z "$CHANGED_FILES" ]; then
            exit 0
          fi

          # Exempt docs-only changes
          ALL_EXEMPT=true
          while IFS= read -r file; do
            case "$file" in
              *.md) ;;
              *) ALL_EXEMPT=false; break ;;
            esac
          done <<< "$CHANGED_FILES"
          if [ "$ALL_EXEMPT" = true ]; then
            exit 0
          fi

          HAS_TESTS=0

WORKFLOW_HEADER

# Append the language-specific test detection
cat "$OVERLAY/commit-msg.partial" >> "$SCRIPT_DIR/.github/workflows/regression-test-check.yml"

cat >> "$SCRIPT_DIR/.github/workflows/regression-test-check.yml" << 'WORKFLOW_FOOTER'

          if [ "$HAS_TESTS" = "1" ]; then
            echo "Test changes found."
            exit 0
          fi

          echo "::warning::This PR looks like a bug fix but contains no test changes."
          echo "::warning::Please add tests, or apply the 'skip-regression-check' label."
          exit 1
WORKFLOW_FOOTER

# --- Build commit-msg hook ---
info "Generating commit-msg hook..."
mkdir -p "$SCRIPT_DIR/.githooks"

cat > "$SCRIPT_DIR/.githooks/commit-msg" << 'HOOK_HEADER'
#!/usr/bin/env bash
# Require regression tests for fix commits.
# Bypass with [skip-regression-check] in the commit message.
set -euo pipefail

MSG_FILE="$1"
FIRST_LINE=$(head -1 "$MSG_FILE")

# Is this a fix commit?
if ! grep -qiE '^(fix(\(.*\))?|hotfix|bugfix):' <<< "$FIRST_LINE"; then
  exit 0
fi

# Skip marker
if grep -qF '[skip-regression-check]' "$MSG_FILE"; then
  exit 0
fi

CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR)
if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

# Exempt docs-only changes
ALL_EXEMPT=true
while IFS= read -r file; do
  case "$file" in
    *.md) ;;
    *) ALL_EXEMPT=false; break ;;
  esac
done <<< "$CHANGED_FILES"
if [ "$ALL_EXEMPT" = true ]; then
  exit 0
fi

HAS_TESTS=0

HOOK_HEADER

cat "$OVERLAY/commit-msg.partial" >> "$SCRIPT_DIR/.githooks/commit-msg"

cat >> "$SCRIPT_DIR/.githooks/commit-msg" << 'HOOK_FOOTER'

if [ "$HAS_TESTS" = "1" ]; then
  exit 0
fi

echo ""
echo "  REGRESSION TEST REQUIRED"
echo ""
echo "  This commit looks like a bug fix but has no test changes."
echo "  Every fix should include a test that reproduces the bug."
echo ""
echo "  Options:"
echo "    - Add a test that catches the bug"
echo "    - Add [skip-regression-check] to your commit message"
echo ""
exit 1
HOOK_FOOTER

chmod +x "$SCRIPT_DIR/.githooks/commit-msg"

# --- Build pre-push hook ---
info "Generating pre-push hook..."

cat > "$SCRIPT_DIR/.githooks/pre-push" << 'PREPUSH_HEADER'
#!/usr/bin/env bash
# Quality gate before push. Skip with: git push --no-verify
set -euo pipefail

echo "Running pre-push quality gate..."
echo ""

PREPUSH_HEADER

cat "$OVERLAY/pre-push.partial" >> "$SCRIPT_DIR/.githooks/pre-push"

cat >> "$SCRIPT_DIR/.githooks/pre-push" << 'PREPUSH_FOOTER'

echo ""
echo "Quality gate passed."
PREPUSH_FOOTER

chmod +x "$SCRIPT_DIR/.githooks/pre-push"

# --- Cursor rules: copy language-specific content into .mdc files ---
info "Updating Cursor rules with language-specific content..."

# Extract body (after frontmatter) from the language rule and prepend Cursor frontmatter
extract_body() {
  local file="$1"
  awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2{print}' "$file"
}

REVIEW_BODY=$(extract_body "$OVERLAY/review-discipline.md")
cat > "$SCRIPT_DIR/.cursor/rules/review-discipline.mdc" << CURSOR_EOF
---
description: Code review and fix discipline
globs: ["src/**", "lib/**", "internal/**", "pkg/**", "cmd/**", "tests/**"]
---
$REVIEW_BODY
CURSOR_EOF

TESTING_BODY=$(extract_body "$OVERLAY/testing.md")
cat > "$SCRIPT_DIR/.cursor/rules/testing.mdc" << CURSOR_EOF
---
description: Testing rules and conventions
globs: ["src/**", "lib/**", "tests/**", "**/*test*", "**/*spec*"]
---
$TESTING_BODY
CURSOR_EOF

# --- Remove unused tool directories ---
if [ "$TOOLS" = "codex" ]; then
  info "Removing .cursor/ (codex-only mode)..."
  rm -rf "$SCRIPT_DIR/.cursor"
fi

# --- Replace project name in files ---
info "Replacing project name placeholders..."
for f in "$SCRIPT_DIR/AGENTS.md" "$SCRIPT_DIR/README.md"; do
  if [ -f "$f" ]; then
    sed -i.bak "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$f" 2>/dev/null || \
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$f" 2>/dev/null || true
    rm -f "${f}.bak"
  fi
done

# --- Clean up ---
info "Removing _lang/ directory..."
rm -rf "$SCRIPT_DIR/_lang"

info "Removing init.sh..."
rm -f "$SCRIPT_DIR/init.sh"

# --- Configure git hooks ---
info "Configuring git hooks..."
if [ -d "$SCRIPT_DIR/.git" ]; then
  git config core.hooksPath .githooks
  ok "Git hooks configured (.githooks/)"
else
  warn "Not a git repo. Run 'git config core.hooksPath .githooks' after git init."
fi

# --- Make scripts executable ---
chmod +x "$SCRIPT_DIR/.github/scripts/"*.sh 2>/dev/null || true
chmod +x "$SCRIPT_DIR/scripts/"*.sh 2>/dev/null || true

# --- Summary ---
echo ""
echo "=================================="
ok "Project '$PROJECT_NAME' initialized!"
echo "=================================="
echo ""
echo "  Language:  $LANG"
echo "  Tools:     $TOOLS"
echo ""
echo "  Next steps:"
echo "    1. Review and customize AGENTS.md for your project"
echo "    2. Run ./scripts/dev-setup.sh --check-only"
echo "    3. Review the Codex skills in skills/"
echo "    4. Run: REPO=owner/repo bash .github/scripts/create-labels.sh"
echo "    5. Start coding!"
echo ""
