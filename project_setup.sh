#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────
# AI-Agent Project Setup Script
# Run from the project root directory.
# Usage: bash project_setup.sh
#
# NOTE: The heredocs below produce shorter versions of the templates
# documented in project_setup.md. Intentional differences:
#   - Agent Rules are condensed (e.g. rule #7 says "Prefer MCP over
#     shell" instead of listing every field). The doc version is the
#     full reference; these are the defaults for new projects.
#   - Template placeholders use shorter prompts (e.g. "{e.g. cargo
#     test}" instead of "{commands the agent should use, e.g. ...}").
#   - Navigation paths omit backtick formatting (plain text in .mdc).
# When editing rules or templates, update BOTH this file and the
# corresponding template section in project_setup.md.
# ──────────────────────────────────────────────

echo "Setting up AI-agent project structure..."

# Create directories
mkdir -p .cursor/rules
mkdir -p docs/arch
mkdir -p docs/tasks
mkdir -p docs/ref

# ── docs/arch/overview.md ──
if [ ! -f docs/arch/overview.md ]; then
cat > docs/arch/overview.md << 'AOVW_EOF'
# Architecture Overview

> Always read this first when you need architecture context.
> It routes you to the right domain doc.

| Domain | Doc | Structure | Description |
|--------|-----|-----------|-------------|

When a domain outgrows a single file, split it into a folder with its own overview.md.
Update this table when adding or restructuring domains.
AOVW_EOF
echo "  Created docs/arch/overview.md"
else
echo "  Skipped docs/arch/overview.md (already exists)"
fi

# ── docs/tasks/overview.md (top-level task overview) ──
if [ ! -f docs/tasks/overview.md ]; then
cat > docs/tasks/overview.md << 'TOVW_EOF'
# Tasks Overview

> Always read this first when working on tasks.
> Shows all groups and cross-group blocking status.

| Group | Status | Blocked by | Description |
|-------|--------|-----------|-------------|
TOVW_EOF
echo "  Created docs/tasks/overview.md"
else
echo "  Skipped docs/tasks/overview.md (already exists)"
fi

# ── docs/ref/overview.md ──
if [ ! -f docs/ref/overview.md ]; then
cat > docs/ref/overview.md << 'ROVW_EOF'
# Reference Overview

> Read this only when a task doc's Context Scope says "Read: docs/ref/..."

| Doc | When to read |
|-----|-------------|
| [requirements.md](requirements.md) | Defining new features, validating scope |
| [roadmap.md](roadmap.md) | Planning releases, checking milestones |
| [lessons.md](lessons.md) | After corrections, or at session start for your domain |
ROVW_EOF
echo "  Created docs/ref/overview.md"
else
echo "  Skipped docs/ref/overview.md (already exists)"
fi

# ── .cursor/rules/project.mdc ──
if [ ! -f .cursor/rules/project.mdc ]; then
cat > .cursor/rules/project.mdc << 'RULE_EOF'
---
description: ProjectName — project context, commands, and agent rules
alwaysApply: true
---

# ProjectName

TODO: One-line description of what this project does.

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Backend | TODO | |
| Database | TODO | |
| Frontend | TODO | |
| Infra | TODO | |

## Project Structure

TODO: paste `tree -L 2 -I node_modules` output here.

## Commands

| Action | Command |
|--------|---------|
| Build | `TODO` |
| Test | `TODO` |
| Lint | `TODO` |
| Run (dev) | `TODO` |

## Navigation

Every docs folder has an overview.md. Always read it first.

- Architecture: docs/arch/overview.md
- Tasks: docs/tasks/overview.md
- Reference: docs/ref/overview.md

## Agent Rules

1. **overview.md first** — When entering any docs folder, read its overview.md first. If you create, rename, or delete any file in the folder, update overview.md immediately.
2. **Plan proportionally** — For 1-2 step tasks, add an inline task to the group overview.md. For 3+ step tasks, create a full task doc in the group folder. Promote an inline task to a full task doc if it needs Context Scope, gets blocked by another task, or grows beyond 2 steps.
3. **Check dependencies** — Before starting a task, read its "Blocked by" field and the group overview.md.
4. **Verify before done** — Run the verification command in the task doc. Never mark complete without proof.
5. **Update status** — Group overview.md is the single source of truth for task status. Follow the Post-Task Checklist after completing any task.
6. **Context scope** — Read ONLY what the task doc's "Context Scope" section says.
7. **Use task tools** — Check the task doc's "Tools & Environment" section. Prefer MCP over shell.
8. **After corrections** — Add to docs/ref/lessons.md. If the pattern recurs, promote it here.
9. **Architecture changes** — Update the relevant docs/arch/ file and its overview.md if structure changed.
10. **Subagents** — One task per subagent. Use the agent type from "Tools & Environment" if specified.
11. **Simplicity** — Minimal changes. Find root causes. No temporary hacks.
12. **Validate overviews** — After adding, removing, or moving any doc, run `bash docs/validate.sh` to ensure overview.md files are in sync.

## Post-Task Checklist

After completing any task:
1. Mark status Done in the group overview.md
2. Fill in the "Files Modified" column in the group overview.md
3. If any file under docs/ was created, renamed, or deleted, update its folder's overview.md
4. Run `bash docs/validate.sh` to verify all overviews are in sync
5. Check if completing this task unblocks other tasks in the group overview.md

## Active Lessons

(None yet. Promote from docs/ref/lessons.md when patterns recur.)

RULE_EOF
echo "  Created .cursor/rules/project.mdc"
else
echo "  Skipped .cursor/rules/project.mdc (already exists)"
fi

# ── docs/tasks/TEMPLATE.md ──
if [ ! -f docs/tasks/TEMPLATE.md ]; then
cat > docs/tasks/TEMPLATE.md << 'TASK_EOF'
# {Task Name}

**Blocked by:** {relative path to prerequisite task, or "none"}
**Group:** {group folder name}

## Context Scope

Read: {docs/arch/backend.md, specific file paths, or section references}
Ignore: {everything else, or specific areas to skip}

## Tools & Environment

> Include only the lines relevant to this task. Delete unused lines.

- **MCP servers:** {e.g. firebase, dart, neo4j -- or "none"}
- **CLI tools:** {e.g. cargo test, npm run build, docker compose up}
- **Agent type:** {e.g. shell, browser-use, generalPurpose -- or "default"}
- **Browser:** {Yes -- URL to verify | No}
- **Scripts:** {e.g. ./restart.sh -- or "none"}
- **Env vars:** {e.g. NEO4J_URI=bolt://localhost:7687 -- or "none"}

## What / Why

{3-5 lines: what this task does, why it exists, what is in/out of scope.}

## Steps

1. [ ] {Step title}
   - {What to do}
   - Verify: `{command}`
   - Expected: {what success looks like}

2. [ ] {Step title}
   - {What to do}
   - Verify: `{command}`
   - Expected: {what success looks like}

## Notes

- Arch impact: {docs/arch/X.md, or "none"}
- Estimated effort: {small / medium / large}

## Files Modified

(Filled on completion. List every file created, modified, or deleted.)

- `path/to/file` — what changed
TASK_EOF
echo "  Created docs/tasks/TEMPLATE.md"
else
echo "  Skipped docs/tasks/TEMPLATE.md (already exists)"
fi

# ── docs/tasks/GROUP_OVERVIEW_TEMPLATE.md ──
if [ ! -f docs/tasks/GROUP_OVERVIEW_TEMPLATE.md ]; then
cat > docs/tasks/GROUP_OVERVIEW_TEMPLATE.md << 'GOVW_EOF'
# {Group Name} Tasks

| Task | File | Status | Blocked by | Files Modified |
|------|------|--------|-----------|---------------|
| {Task 1} | [task-1.md](task-1.md) | Not started | -- | -- |
| {Task 2} | [task-2.md](task-2.md) | Not started | task-1.md | -- |

## Inline Tasks

- [ ] {Small task} — {What to do}. Verify: `{command}`

<!-- Optional: add a mermaid dependency graph only if the group has
     complex non-linear dependencies (5+ tasks with branching). -->

Cross-group dependencies: none
GOVW_EOF
echo "  Created docs/tasks/GROUP_OVERVIEW_TEMPLATE.md"
else
echo "  Skipped docs/tasks/GROUP_OVERVIEW_TEMPLATE.md (already exists)"
fi

# ── docs/arch/TEMPLATE.md ──
if [ ! -f docs/arch/TEMPLATE.md ]; then
cat > docs/arch/TEMPLATE.md << 'ARCH_EOF'
# {Domain Name} Architecture

> Read this when working on {domain} tasks. See `.cursor/rules/project.mdc`
> for project overview and commands.

## Overview

{2-3 sentences: what this component does, its boundaries.}

## Design Decisions

- {Decision 1: what was chosen and why}
- {Decision 2: ...}

## Key Modules / Files

| Module | Path | Responsibility |
|--------|------|---------------|
| | | |

## Data Flow

{Describe or diagram the key data flows for this domain.}

## API Surface

{Endpoints, tool interfaces, or public APIs this domain exposes.}
ARCH_EOF
echo "  Created docs/arch/TEMPLATE.md"
else
echo "  Skipped docs/arch/TEMPLATE.md (already exists)"
fi

# ── docs/ref/lessons.md ──
if [ ! -f docs/ref/lessons.md ]; then
cat > docs/ref/lessons.md << 'LESSONS_EOF'
# Lessons Learned

> Corrections log. After any user correction, add an entry below.
> When a pattern recurs (2+ times), promote it to an Active Lesson
> in `.cursor/rules/project.mdc` so it is auto-loaded every session.

## Lessons

| Date | What happened | Rule | Promoted? |
|------|--------------|------|-----------|
| | | | |
LESSONS_EOF
echo "  Created docs/ref/lessons.md"
else
echo "  Skipped docs/ref/lessons.md (already exists)"
fi

# ── docs/ref/requirements.md ──
if [ ! -f docs/ref/requirements.md ]; then
cat > docs/ref/requirements.md << 'REQ_EOF'
# Requirements

> Functional and non-functional requirements. Read when defining new features
> or validating scope. Not auto-loaded — referenced from task docs when needed.

## Functional Requirements

| ID | Requirement | Description |
|----|-------------|-------------|
| FR-1 | TODO | |

## Non-Functional Requirements

| ID | Category | Requirement | Notes |
|----|----------|-------------|-------|
| NFR-1 | Performance | TODO | |
REQ_EOF
echo "  Created docs/ref/requirements.md"
else
echo "  Skipped docs/ref/requirements.md (already exists)"
fi

# ── docs/ref/roadmap.md ──
if [ ! -f docs/ref/roadmap.md ]; then
cat > docs/ref/roadmap.md << 'ROAD_EOF'
# Roadmap

> Development phases and changelog. Not auto-loaded — read when planning
> releases or reviewing project history.

## Phases

| Phase | Status | Description |
|-------|--------|-------------|
| 1 | In progress | TODO |

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| | 0.1.0 | Initial setup |
ROAD_EOF
echo "  Created docs/ref/roadmap.md"
else
echo "  Skipped docs/ref/roadmap.md (already exists)"
fi

# ── docs/validate.sh ──
if [ ! -f docs/validate.sh ]; then
cat > docs/validate.sh << 'VALIDATE_EOF'
#!/usr/bin/env bash
# Checks that every .md file and subdirectory in docs/ folders is listed
# in its parent overview.md. Recurses into all subdirectories.
# Run before starting work or as a git pre-commit hook

errors=0

check_dir() {
  local dir="$1"
  [ ! -d "$dir" ] && return
  local overview="$dir/overview.md"
  [ ! -f "$overview" ] && { echo "MISSING: $overview"; errors=$((errors+1)); return; }

  for f in "$dir"/*.md; do
    [ ! -f "$f" ] && continue
    [ "$f" = "$overview" ] && continue
    local base
    base=$(basename "$f")
    [ "$base" = "TEMPLATE.md" ] && continue
    [ "$base" = "GROUP_OVERVIEW_TEMPLATE.md" ] && continue
    if ! grep -q "$base" "$overview"; then
      echo "NOT IN OVERVIEW: $f missing from $overview"
      errors=$((errors+1))
    fi
  done

  for subdir in "$dir"/*/; do
    [ ! -d "$subdir" ] && continue
    local subdir_name
    subdir_name=$(basename "$subdir")
    [ "$subdir_name" = "archive" ] && continue
    if ! grep -q "$subdir_name" "$overview"; then
      echo "NOT IN OVERVIEW: $subdir missing from $overview"
      errors=$((errors+1))
    fi
    check_dir "$subdir"
  done
}

for root in docs/arch docs/tasks docs/ref; do
  check_dir "$root"
done

if [ $errors -eq 0 ]; then
  echo "All overview.md files are in sync."
else
  echo "$errors inconsistencies found. Update the relevant overview.md files."
  exit 1
fi
VALIDATE_EOF
chmod +x docs/validate.sh
echo "  Created docs/validate.sh"
else
echo "  Skipped docs/validate.sh (already exists)"
fi

echo ""
echo "Verifying setup..."
bash docs/validate.sh

echo ""
echo "Done. Next steps:"
echo "  1. Fill in .cursor/rules/project.mdc with your project's tech stack, structure, and commands"
echo "  2. Create docs/arch/{domain}.md files and add rows to docs/arch/overview.md"
echo "  3. When work begins, create task group folders: mkdir docs/tasks/{group}/"
echo "     Copy GROUP_OVERVIEW_TEMPLATE.md -> docs/tasks/{group}/overview.md"
echo "     Copy TEMPLATE.md -> docs/tasks/{group}/{task-name}.md"
echo "     Add a row to docs/tasks/overview.md for the group"
echo ""
echo "Convention: every folder has an overview.md -- agent always reads it first."
echo "Per-session cost: ~350 lines (cursor rule + arch overview + domain doc + group overview + task doc)"
