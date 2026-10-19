#!/usr/bin/env bash
# Coverage check script.
# Enforces the minimum line coverage set in check_coverage.dart, from coverage/lcov.info.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LCOV_FILE="${1:-$REPO_ROOT/coverage/lcov.info}"

if [ ! -f "$LCOV_FILE" ]; then
  echo "ERROR: Coverage file not found at '$LCOV_FILE'." >&2
  echo "Run 'flutter test --coverage' first." >&2
  exit 1
fi

dart "$SCRIPT_DIR/check_coverage.dart" "$LCOV_FILE"
