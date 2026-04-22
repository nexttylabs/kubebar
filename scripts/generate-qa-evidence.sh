#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ] || [ "$1" != "--output" ]; then
  echo "Usage: $0 --output <directory>" >&2
  exit 1
fi

OUTPUT_DIR="$2"
OUTPUT_FILE="${OUTPUT_DIR}/07-UAT.generated.md"

mkdir -p "$OUTPUT_DIR"

cat > "$OUTPUT_FILE" <<'EOF'
# Phase 07 UAT Generated Evidence

| State | Status | Reproduction steps | Expected behavior | Observed behavior | Evidence path | Limitations | Follow-up risk |
|-------|--------|--------------------|-------------------|-------------------|---------------|-------------|----------------|
| Healthy | pending-human-verification | `./scripts/compile-and-run.sh --qa-state healthy` | Menu shows OK with healthy counters and watched namespaces. | pending-human-verification | `docs/assets/qa/phase-07-healthy.png` | Screenshot or visible menu check may require human action. | Do not mark complete without visible evidence. |
| Watch | pending-human-verification | `./scripts/compile-and-run.sh --qa-state watch` | Menu shows Watch with warning context and non-healthy attention. | pending-human-verification | `docs/assets/qa/phase-07-watch.png` | Screenshot or visible menu check may require human action. | Do not mark complete without visible evidence. |
| Bad | pending-human-verification | `./scripts/compile-and-run.sh --qa-state bad` | Menu shows Bad and prioritizes the broken watched target. | pending-human-verification | `docs/assets/qa/phase-07-bad.png` | Screenshot or visible menu check may require human action. | Do not mark complete without visible evidence. |
| Stale refresh failure | pending-human-verification | `./scripts/compile-and-run.sh --qa-state stale-refresh-failure` | Menu shows Stale while preserving last known status. | pending-human-verification | `docs/assets/qa/phase-07-stale-refresh-failure.png` | Screenshot or visible menu check may require human action. | Do not mark complete without visible evidence. |
| Stale age-out | pending-human-verification | `./scripts/compile-and-run.sh --qa-state stale-age-out` | Menu shows Stale because the last successful refresh is too old. | pending-human-verification | `docs/assets/qa/phase-07-stale-age-out.png` | Screenshot or visible menu check may require human action. | Do not mark complete without visible evidence. |
| first-use | pending-human-verification | `./scripts/compile-and-run.sh --qa-state first-use` | Menu shows setup before any saved context exists. | pending-human-verification | `docs/assets/qa/phase-07-first-use.png` | Screenshot or visible menu check may require human action. | Do not mark complete without visible evidence. |
| empty-watchlist | pending-human-verification | `./scripts/compile-and-run.sh --qa-state empty-watchlist` | Menu shows setup because prod has no selected namespaces. | pending-human-verification | `docs/assets/qa/phase-07-empty-watchlist.png` | Screenshot or visible menu check may require human action. | Do not mark complete without visible evidence. |
| kubectl failure | pending-human-verification | `./scripts/compile-and-run.sh --qa-state kubectl-failure` | Menu shows Stale with a safe failure message and retained prior status. | pending-human-verification | `docs/assets/qa/phase-07-kubectl-failure.png` | Screenshot or visible menu check may require human action. | Do not mark complete without visible evidence. |
EOF

test -s "$OUTPUT_FILE"

for label in \
  "Healthy" \
  "Watch" \
  "Bad" \
  "Stale refresh failure" \
  "Stale age-out" \
  "first-use" \
  "empty-watchlist" \
  "kubectl failure" \
  "pending-human-verification"; do
  if ! grep -q "$label" "$OUTPUT_FILE"; then
    echo "Generated evidence is missing required label: $label" >&2
    exit 1
  fi
done

echo "Generated ${OUTPUT_FILE}"
