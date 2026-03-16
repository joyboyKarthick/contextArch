#!/usr/bin/env bash
# Tests for project_setup.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

print_section "project_setup.sh tests"

# ── Test 1: Creates all directories ──

setup_sandbox
bash project_setup.sh >/dev/null 2>&1
assert_dir_exists ".cursor/rules" "Creates .cursor/rules directory"
assert_dir_exists "docs/arch"     "Creates docs/arch directory"
assert_dir_exists "docs/tasks"    "Creates docs/tasks directory"
assert_dir_exists "docs/ref"      "Creates docs/ref directory"
teardown_sandbox

# ── Test 2: Creates all 11 expected files ──

setup_sandbox
bash project_setup.sh >/dev/null 2>&1
expected_files=(
  ".cursor/rules/project.mdc"
  "docs/arch/overview.md"
  "docs/arch/TEMPLATE.md"
  "docs/tasks/overview.md"
  "docs/tasks/TEMPLATE.md"
  "docs/tasks/GROUP_OVERVIEW_TEMPLATE.md"
  "docs/ref/overview.md"
  "docs/ref/lessons.md"
  "docs/ref/requirements.md"
  "docs/ref/roadmap.md"
  "docs/validate.sh"
)
all_exist=true
missing=""
for f in "${expected_files[@]}"; do
  if [ ! -f "$f" ]; then
    all_exist=false
    missing="$missing $f"
  fi
done
if $all_exist; then
  _record_pass "Creates all 11 expected files"
else
  _record_fail "Creates all 11 expected files" "Missing:$missing"
fi
teardown_sandbox

# ── Test 3: validate.sh is executable ──

setup_sandbox
bash project_setup.sh >/dev/null 2>&1
assert_executable "docs/validate.sh" "validate.sh is executable"
teardown_sandbox

# ── Test 4: project.mdc has alwaysApply: true ──

setup_sandbox
bash project_setup.sh >/dev/null 2>&1
assert_file_contains ".cursor/rules/project.mdc" "alwaysApply: true" \
  "project.mdc has alwaysApply: true"
teardown_sandbox

# ── Test 5: project.mdc has all 12 Agent Rules ──

setup_sandbox
bash project_setup.sh >/dev/null 2>&1
rules_found=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  if grep -q "^${i}\." ".cursor/rules/project.mdc" 2>/dev/null; then
    rules_found=$((rules_found + 1))
  fi
done
assert_eq "$rules_found" "12" "project.mdc has all 12 Agent Rules"
teardown_sandbox

# ── Test 6: Idempotency -- does not overwrite existing files ──

setup_sandbox
mkdir -p docs/arch
echo "CUSTOM CONTENT" > docs/arch/overview.md
bash project_setup.sh >/dev/null 2>&1
actual=$(cat docs/arch/overview.md)
assert_eq "$actual" "CUSTOM CONTENT" "Idempotency: does not overwrite existing files"
teardown_sandbox

# ── Test 7: Idempotency -- prints "Skipped" for existing files ──

setup_sandbox
mkdir -p docs/arch
echo "existing" > docs/arch/overview.md
output=$(bash project_setup.sh 2>&1)
assert_output_contains "$output" "Skipped docs/arch/overview.md" \
  "Idempotency: prints Skipped for existing files"
teardown_sandbox

# ── Test 8: Self-validates after setup ──

setup_sandbox
bash project_setup.sh >/dev/null 2>&1
bash docs/validate.sh >/dev/null 2>&1
assert_exit_code $? 0 "Self-validates: validate.sh passes after setup"
teardown_sandbox

# ── Test 9: Output contains success message ──

setup_sandbox
output=$(bash project_setup.sh 2>&1)
assert_output_contains "$output" "Done. Next steps:" \
  "Output contains success message"
teardown_sandbox

# ── Test 10: overview.md files have correct structure ──

setup_sandbox
bash project_setup.sh >/dev/null 2>&1
assert_file_contains "docs/arch/overview.md" "| Domain | Doc | Structure | Description |" \
  "docs/arch/overview.md has domain table header"
assert_file_contains "docs/tasks/overview.md" "| Group | Status | Blocked by | Description |" \
  "docs/tasks/overview.md has group table header"
assert_file_contains "docs/ref/overview.md" "requirements.md" \
  "docs/ref/overview.md lists requirements.md"
assert_file_contains "docs/ref/overview.md" "roadmap.md" \
  "docs/ref/overview.md lists roadmap.md"
assert_file_contains "docs/ref/overview.md" "lessons.md" \
  "docs/ref/overview.md lists lessons.md"
teardown_sandbox

# ── Test 11: Template files have placeholders ──

setup_sandbox
bash project_setup.sh >/dev/null 2>&1
assert_file_contains "docs/tasks/TEMPLATE.md" "{Task Name}" \
  "Task TEMPLATE.md contains {Task Name} placeholder"
assert_file_contains "docs/arch/TEMPLATE.md" "{Domain Name}" \
  "Arch TEMPLATE.md contains {Domain Name} placeholder"
assert_file_contains "docs/tasks/GROUP_OVERVIEW_TEMPLATE.md" "{Group Name}" \
  "GROUP_OVERVIEW_TEMPLATE.md contains {Group Name} placeholder"
teardown_sandbox

# ── Test 12: Post-Task Checklist present in project.mdc ──

setup_sandbox
bash project_setup.sh >/dev/null 2>&1
assert_file_contains ".cursor/rules/project.mdc" "Post-Task Checklist" \
  "project.mdc has Post-Task Checklist section"
checklist_items=0
for phrase in "Mark status Done" "Files Modified" "created, renamed, or deleted" "validate.sh" "unblocks other tasks"; do
  if grep -q "$phrase" ".cursor/rules/project.mdc" 2>/dev/null; then
    checklist_items=$((checklist_items + 1))
  fi
done
assert_eq "$checklist_items" "5" "Post-Task Checklist has all 5 items"
teardown_sandbox
