#!/usr/bin/env bash
# Runs all headless test suites. Requires a Godot 4.6 binary.
# Usage: GODOT=/path/to/godot tools/run_tests.sh   (defaults to `godot` on PATH)
set -u

GODOT_BIN="${GODOT:-godot}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXIT_CODE=0

SUITES=(
	"tests/content/content_validation_test.gd"
	"tests/unit/simulation_systems_test.gd"
	"tests/unit/scanner_station_test.gd"
	"tests/unit/run_controller_flow_test.gd"
)

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
	echo "Godot binary not found ('$GODOT_BIN'). Set GODOT=/path/to/godot." >&2
	exit 1
fi

# First import resolves resources/UIDs so the suites see a consistent project.
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --import >/dev/null 2>&1

for suite in "${SUITES[@]}"; do
	echo "==> $suite"
	if ! "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script "$suite"; then
		EXIT_CODE=1
	fi
done

exit $EXIT_CODE
