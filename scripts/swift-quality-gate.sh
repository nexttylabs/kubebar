#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-local}"

echo "Swift quality gate mode: $MODE"
echo "Running Swift build check"
swift build

echo "Running Swift test check"
swift test
