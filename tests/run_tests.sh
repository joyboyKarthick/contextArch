#!/usr/bin/env bash
# Test runner for ContextArch.
# Runs all test files and prints a combined summary.
#
# Usage: bash tests/run_tests.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/test_helpers.sh"

source "$SCRIPT_DIR/test_project_setup.sh"
source "$SCRIPT_DIR/test_validate.sh"

print_summary
exit $?
