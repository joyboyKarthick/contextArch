#!/usr/bin/env bash
# Lightweight test helpers for ContextArch bash tests.
# Source this file at the top of each test file.

PASS_COUNT=${PASS_COUNT:-0}
FAIL_COUNT=${FAIL_COUNT:-0}
SANDBOX_DIR=""
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

setup_sandbox() {
  SANDBOX_DIR="$(mktemp -d)"
  cp "$PROJECT_ROOT/project_setup.sh" "$SANDBOX_DIR/"
  cd "$SANDBOX_DIR" || exit 1
}

teardown_sandbox() {
  cd "$PROJECT_ROOT" || exit 1
  [ -n "$SANDBOX_DIR" ] && rm -rf "$SANDBOX_DIR"
  SANDBOX_DIR=""
}

_record_pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf "  \033[32mPASS\033[0m  %s\n" "$1"
}

_record_fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf "  \033[31mFAIL\033[0m  %s\n" "$1"
  [ -n "$2" ] && printf "        %s\n" "$2"
}

assert_file_exists() {
  local file="$1" label="$2"
  if [ -f "$file" ]; then
    _record_pass "$label"
  else
    _record_fail "$label" "File not found: $file"
  fi
}

assert_dir_exists() {
  local dir="$1" label="$2"
  if [ -d "$dir" ]; then
    _record_pass "$label"
  else
    _record_fail "$label" "Directory not found: $dir"
  fi
}

assert_file_contains() {
  local file="$1" pattern="$2" label="$3"
  if grep -q "$pattern" "$file" 2>/dev/null; then
    _record_pass "$label"
  else
    _record_fail "$label" "Pattern '$pattern' not found in $file"
  fi
}

assert_file_not_contains() {
  local file="$1" pattern="$2" label="$3"
  if ! grep -q "$pattern" "$file" 2>/dev/null; then
    _record_pass "$label"
  else
    _record_fail "$label" "Pattern '$pattern' unexpectedly found in $file"
  fi
}

assert_output_contains() {
  local output="$1" pattern="$2" label="$3"
  if echo "$output" | grep -q "$pattern"; then
    _record_pass "$label"
  else
    _record_fail "$label" "Pattern '$pattern' not found in output"
  fi
}

assert_exit_code() {
  local actual="$1" expected="$2" label="$3"
  if [ "$actual" -eq "$expected" ]; then
    _record_pass "$label"
  else
    _record_fail "$label" "Expected exit code $expected, got $actual"
  fi
}

assert_eq() {
  local actual="$1" expected="$2" label="$3"
  if [ "$actual" = "$expected" ]; then
    _record_pass "$label"
  else
    _record_fail "$label" "Expected '$expected', got '$actual'"
  fi
}

assert_executable() {
  local file="$1" label="$2"
  if [ -x "$file" ]; then
    _record_pass "$label"
  else
    _record_fail "$label" "File not executable: $file"
  fi
}

print_section() {
  printf "\n\033[1m=== %s ===\033[0m\n" "$1"
}

print_summary() {
  local total=$((PASS_COUNT + FAIL_COUNT))
  printf "\n\033[1m=== SUMMARY ===\033[0m\n"
  printf "  %s passed, %s failed (out of %s)\n" "$PASS_COUNT" "$FAIL_COUNT" "$total"
  [ "$FAIL_COUNT" -gt 0 ] && return 1
  return 0
}
