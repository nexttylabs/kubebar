#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/generate-changelog-candidates.sh [OPTIONS]

Options:
  --from <ref>         Start ref (exclusive). Defaults to latest v* tag before --to.
  --to <ref>           End ref. Defaults to HEAD.
  --output-prefix <id> Prefix used in generated filenames.
  --print-summary      Print only a short summary line (still writes files).
  --help               Show this message.
USAGE
}

FROM_REF=""
TO_REF="HEAD"
OUTPUT_PREFIX=""
PRINT_SUMMARY=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --from|-f)
      FROM_REF="${2:-}"
      shift 2
      ;;
    --to|-t)
      TO_REF="${2:-}"
      shift 2
      ;;
    --output-prefix|-p)
      OUTPUT_PREFIX="${2:-}"
      shift 2
      ;;
    --print-summary|-s)
      PRINT_SUMMARY=1
      shift 1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [ -z "$FROM_REF" ]; then
  FROM_REF="$(git describe --tags --match 'v*' --abbrev=0 "${TO_REF}^" 2>/dev/null || true)"
fi

if [ -z "$FROM_REF" ]; then
  RANGE="$TO_REF"
else
  RANGE="${FROM_REF}..${TO_REF}"
fi

OUTPUT_DIR="changelog.d"
mkdir -p "$OUTPUT_DIR"

TS="$(date +%Y%m%d-%H%M%S)"
SAFE_TO="$(printf '%s' "$TO_REF" | tr '/:' '--')"
SAFE_FROM="$(printf '%s' "${FROM_REF:-head}" | tr '/:' '--')"
if [ -z "$OUTPUT_PREFIX" ]; then
  OUTPUT_PREFIX="changelog-candidates-${TS}-${SAFE_FROM}-to-${SAFE_TO}"
fi

cleanup_type_file() {
  local file="$1"
  if [ -f "$file" ]; then
    local sorted
    sorted="$(mktemp)"
    awk 'NF {if (!seen[$0]++) print $0}' "$file" | sort > "$sorted"
    mv "$sorted" "$file"
  fi
}

add_line() {
  local target_type="$1"
  local line="$2"
  local file
  file="$OUTPUT_DIR/${OUTPUT_PREFIX}.${target_type}.md"
  if [ -z "$line" ]; then
    return 0
  fi
  printf -- '- %s\n' "$line" >> "$file"
}

map_type() {
  local commit_type="$1"
  case "$commit_type" in
    feat|feature|enhancement|added|add)
      echo "added"
      ;;
    fix|bugfix)
      echo "fixed"
      ;;
    docs|documentation|doc)
      echo "documentation"
      ;;
    deprecated|deprecate|deprecation)
      echo "deprecated"
      ;;
    removed|remove|delete)
      echo "removed"
    ;;
    security)
      echo "security"
      ;;
    *)
      echo "changed"
      ;;
  esac
}

extract_message_type_and_text() {
  local message="$1"
  local kind
  local body
  local pattern
  local text
  local target

  text="$(printf '%s' "$message" | sed -n '1p')"
  if [[ "$text" == Merge\ pull\ request\ * ]]; then
    body="$(printf '%s' "$message" | sed -n '2,$p' | sed '/^$/d' | head -n 1)"
    if [ -n "$body" ]; then
      text="$body"
    fi
  fi

  pattern='^([[:alpha:]]+)(\([^)]*\))?:[[:space:]]*(.+)$'
  if [[ "$text" =~ $pattern ]]; then
    kind="${BASH_REMATCH[1]}"
    text="${BASH_REMATCH[3]}"
  else
    kind="changed"
  fi

  text="$(printf '%s' "$text" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ -z "$text" ]; then
    return 0
  fi

  target="$(map_type "$kind")"
  add_line "$target" "$text"
}

if [ -n "${GIT_DIR:-}" ] && [ ! -d "$GIT_DIR" ]; then
  echo "Current directory is not a git repository." >&2
  exit 1
fi

commit_count=0
for sha in $(git rev-list --reverse "$RANGE"); do
  message="$(git log -1 --pretty=%B "$sha")"
  if [ -n "$message" ]; then
    extract_message_type_and_text "$message"
    commit_count=$((commit_count + 1))
  fi
done

files=0
for type in added changed deprecated removed fixed security documentation; do
  file="$OUTPUT_DIR/${OUTPUT_PREFIX}.${type}.md"
  cleanup_type_file "$file"
  if [ -f "$file" ] && [ -s "$file" ]; then
    files=$((files + 1))
  else
    rm -f "$file"
  fi
done

if [ "$files" -eq 0 ]; then
  echo "No changelog candidates generated for range $RANGE (inspect commit messages and PR titles)." >&2
  exit 0
fi

for type in added changed deprecated removed fixed security documentation; do
  file="$OUTPUT_DIR/${OUTPUT_PREFIX}.${type}.md"
  if [ -s "$file" ]; then
    if [ "$PRINT_SUMMARY" -eq 1 ]; then
      echo "$file"
    else
      echo "Created $file:"
      sed -n '1,200p' "$file"
    fi
  fi
done

if [ "$PRINT_SUMMARY" -eq 0 ]; then
  echo ""
  echo "Source range: $RANGE"
  echo "Generated candidates: ${files} file(s)"
  echo "Please review and edit these files, then run prepare-changelog-release.sh."
fi
