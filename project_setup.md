# Project Setup for AI-Agent-Driven Development

**Version 2.0**

> **What:** Load this file into an AI agent when starting a new project. The agent reads this, then executes the setup to create a 3-tier context architecture that eliminates context rot and redundant loading across sessions.
>
> **How:** Give this file to your agent with: "Set up this project using the project_setup.md system. Project name is {X}, tech stack is {Y}."
>
> **After setup:** This file is reference material only. The agent's entry point becomes `.cursor/rules/project.mdc`, which is auto-loaded every session. You do not need to load this file again unless modifying the system itself.

<details>
<summary>Changelog</summary>

- **v2.0** -- Extracted standalone `project_setup.sh`. Added Post-Task Checklist, Files Modified tracking, inline task promotion rule. Replaced vague "seems stale" triggers with concrete file-change triggers. Standardized Blocked-by on `filename.md`. Made mermaid optional. Recursive `validate.sh`. Lifecycle note. Split enterprise patterns to separate file.
- **v1.0** -- Initial release. 3-tier architecture, overview.md convention, templates, setup script, agent rules.

</details>

---

## The Problem This Solves

When AI agents build software, they waste context window on:
- **Repeated context** -- tech stack, structure, commands repeated every session
- **Context rot** -- dozens of MD files, most irrelevant to the current task
- **Navigation chains** -- reading 6-8 files before writing a single line of code
- **Redundant instructions** -- agent behavior defined in 3+ places

This system fixes all of that with a 3-tier context architecture where an agent reads 2-3 files per session instead of 8-9.

---

## 3-Tier Context Architecture

```
Tier 0  [Always auto-loaded]     .cursor/rules/project.mdc  (~60-100 lines)
         |                        Project identity + commands + agent rules
         |
Tier 1  [overview.md first]      docs/arch/overview.md  (~20-50 lines, routes agent)
         |--- [Per-domain]        docs/arch/{domain}.md  or  docs/arch/{domain}/overview.md
         |                        Architecture per component (~100-200 lines each)
         |
Tier 2  [overview.md first]      docs/tasks/overview.md  (~15-25 lines, cross-group status)
         |--- [Per-group]         docs/tasks/{group}/overview.md  (~15-25 lines, deps + status)
         |    |--- [Per-task]     docs/tasks/{group}/{task}.md  (~30-80 lines)
         |
Tier 3  [overview.md first]      docs/ref/overview.md  (~10-15 lines, lists what's available)
         |--- [On-demand]         docs/ref/requirements.md, roadmap.md, lessons.md
```

**Per-session cost:** cursor rule (auto) + arch overview + 1 arch doc + group overview + 1 task doc = ~350 lines. No chains.

**Universal convention:** Every folder the agent might enter has an `overview.md`. The agent ALWAYS reads `overview.md` first. It either IS the content (simple section) or routes to the right sub-doc (complex section). If you create, rename, or delete any file in the folder, update overview.md immediately. This convention scales independently -- you can restructure any section from flat to deeply nested without changing the agent's navigation pattern.

### Tier 0: `.cursor/rules/project.mdc`

The SINGLE entry point. Auto-loaded by Cursor every session. Contains:
- Project identity (name, one-liner, tech stack table)
- Project structure (tree, 10-15 lines)
- Key commands (build, test, lint, run, deploy)
- Agent rules (plan, verify, lessons -- defined HERE, nowhere else)
- Active lessons (promoted from lessons.md when patterns recur)

**No routing table.** The cursor rule tells the agent: "read `docs/arch/overview.md` for architecture, `docs/tasks/overview.md` for tasks, `docs/ref/overview.md` for reference." The overviews handle all routing. This keeps the cursor rule stable even as the project adds domains.

### Tier 1: `docs/arch/`

Architecture docs, organized however fits the project. Always start with `docs/arch/overview.md`.

**`docs/arch/overview.md`** lists all domains and tells the agent which doc to read. It scales independently -- add rows as the project grows, no cursor rule changes needed.

**Flexible structure per domain:**

```
docs/arch/
  overview.md                   # Always read first -- routes to domain docs
  backend.md                    # Simple domain: single file
  database.md                   # Simple domain: single file
  payments/                     # Complex domain: sub-folder
    overview.md                 # Routes to sub-docs within payments
    processing.md
    billing.md
    compliance.md
  ui.md                         # Simple domain: single file
```

- **Simple domain** (e.g., `backend.md`): overview.md points to it directly. One file, 100-200 lines.
- **Complex domain** (e.g., `payments/`): overview.md points to `payments/overview.md`, which routes to sub-docs. Each sub-doc stays under 200 lines.
- **Growing domain**: When a single-file domain outgrows 200 lines, split it into a folder with its own overview.md. Only update `docs/arch/overview.md` to point to the new path -- nothing else changes.

### Tier 2: `docs/tasks/`

Task docs, grouped by domain. Always start with `docs/tasks/overview.md`.

```
docs/tasks/
  overview.md                   # Always read first -- all groups, cross-group status
  backend/
    overview.md                 # Group overview: status table + dependency graph
    graph-schema.md             # Task doc (~30-80 lines)
    repo-discovery.md
    sync-branch-aware.md
  ui/
    overview.md
    explorer-cytoscape.md
    blast-radius-highlight.md
  TEMPLATE.md                   # Copy into a group folder and rename
```

**`docs/tasks/overview.md`** lists all groups and cross-group blocking status. Agent reads this first to understand the big picture.

**`docs/tasks/{group}/overview.md`** (keep scannable) contains:
- A status table (task name, status, blocked by)
- Inline tasks (1-2 step items that don't need a separate file)
- An optional mermaid dependency graph (only for complex non-linear dependencies)
- Cross-group dependency notes
- No prose, no architecture -- just dependency tracking

**Task docs** include a "Blocked by" field referencing prerequisite tasks by relative path.

**Acceptance criteria are mandatory.** Every task doc and every step must have explicit verification: a **Verify** command and an **Expected** outcome. Do not create or complete a task without these. Inline tasks in the group overview must also include a Verify command.

**Navigation:** Agent reads group overview.md to find the right task, then reads the task doc. 2 levels max.

### Tier 3: `docs/ref/`

Reference material. Always start with `docs/ref/overview.md`.

**`docs/ref/overview.md`** lists what's available and when to read each file:

```
docs/ref/
  overview.md                   # What's here and when to read it
  requirements.md               # FR/NFR -- read when defining features
  roadmap.md                    # Phases, changelog -- read when planning releases
  lessons.md                    # Corrections log -- read at session start for your domain
```

The agent reads `docs/ref/overview.md` only when a task doc's Context Scope says "Read: docs/ref/..." -- not by default.

---

## Templates

### Template: `.cursor/rules/project.mdc`

```
---
description: {ProjectName} — project context, commands, and agent rules
alwaysApply: true
---

# {ProjectName}

{One-line description of what this project does.}

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Backend | {e.g. Rust, Node.js, Python} | {version, key libs} |
| Database | {e.g. PostgreSQL, Neo4j} | {version} |
| Frontend | {e.g. React, Vue, None} | {framework, build tool} |
| Infra | {e.g. Docker, K8s, None} | {compose, cloud} |

## Project Structure

{tree output, 10-20 lines, showing key directories only}

## Commands

| Action | Command |
|--------|---------|
| Build | `{build command}` |
| Test | `{test command}` |
| Lint | `{lint command}` |
| Run (dev) | `{dev run command}` |
| Run (prod) | `{prod run command}` |

## Navigation

Every docs folder has an `overview.md`. Always read it first -- it routes you to the right file.

- Architecture: `docs/arch/overview.md`
- Tasks: `docs/tasks/overview.md`
- Reference: `docs/ref/overview.md`

## Agent Rules

1. **overview.md first** — When entering any docs folder, read its `overview.md` first. If you create, rename, or delete any file in the folder, update overview.md immediately.
2. **Plan proportionally** — For 1-2 step tasks, add an inline task to the group overview.md. For 3+ step tasks, create a full task doc in the group folder. Promote an inline task to a full task doc if it needs Context Scope, gets blocked by another task, or grows beyond 2 steps. Every task (inline or full doc) must have acceptance criteria: a Verify command and Expected outcome per step.
3. **Test-driven by default** — Follow test-driven design: write a failing test (or verification) first, then implement to pass it. If the user prefers a different approach (e.g. implement then test, or skip tests for this task), follow their preference.
4. **Check dependencies** — Before starting a task, read its "Blocked by" field. If prerequisites are not Done, do not start. Read the group overview.md for the dependency graph.
5. **Verify before done** — Run the verification command in the task doc. Never mark complete without proof. Acceptance criteria (Verify + Expected) are mandatory for every step.
6. **Update status** — Group overview.md is the single source of truth for task status. Follow the Post-Task Checklist after completing any task.
7. **Context scope** — Read ONLY what the task doc's "Context Scope" section says. Do not read unrelated docs.
8. **Use task tools** — Check the task doc's "Tools & Environment" section. Use the specified MCP servers, CLI tools, agent types, browser, scripts, and env vars. Prefer MCP tools over raw shell commands when an MCP server is listed.
9. **After corrections** — Add to `docs/ref/lessons.md`. If the pattern recurs, promote it to a rule here.
10. **Architecture changes** — If the task changes design/modules/API/data flow, update the relevant `docs/arch/` file and its overview.md if the structure changed.
11. **Subagents** — One task per subagent. Use the agent type from "Tools & Environment" if specified.
12. **Simplicity** — Minimal changes. Find root causes. No temporary hacks.
13. **Validate overviews** — After adding, removing, or moving any doc, run `bash docs/validate.sh` to ensure overview.md files are in sync.

## Post-Task Checklist

After completing any task:
1. Mark status Done in the group overview.md
2. Fill in the "Files Modified" column in the group overview.md
3. If any file under `docs/` was created, renamed, or deleted, update its folder's overview.md
4. Run `bash docs/validate.sh` to verify all overviews are in sync
5. Check if completing this task unblocks other tasks in the group overview.md

## Active Lessons

(Promoted from docs/ref/lessons.md when patterns recur. Add entries here so they are auto-loaded.)

```

### Template: `docs/arch/overview.md` (architecture entry point)

```markdown
# Architecture Overview

> Always read this first when you need architecture context.
> It routes you to the right domain doc.

| Domain | Doc | Structure | Description |
|--------|-----|-----------|-------------|
| Backend | [backend.md](backend.md) | Single file | REST API, MCP server, sync engine |
| Database | [database.md](database.md) | Single file | Graph schema, Neo4j, Cypher |
| Payments | [payments/overview.md](payments/overview.md) | Sub-folder | Processing, billing, compliance |
| UI | [ui.md](ui.md) | Single file | React app, graph visualization |
| Deployment | [deployment.md](deployment.md) | Single file | Docker, CI/CD |

When a domain outgrows a single file, split it into a folder with its own overview.md.
Update this table when adding or restructuring domains.
```

### Template: `docs/tasks/overview.md` (top-level task overview)

```markdown
# Tasks Overview

> Always read this first when working on tasks.
> Shows all groups and cross-group blocking status.

| Group | Status | Blocked by | Description |
|-------|--------|-----------|-------------|
| [backend/](backend/) | In progress | -- | API, sync, MCP tools |
| [ui/](ui/) | Blocked | backend/ | Graph visualization |
| [deployment/](deployment/) | Not started | backend/ | Docker, CI/CD |
```

### Template: `docs/tasks/{group}/overview.md` (group task overview)

```markdown
# {Group Name} Tasks

| Task | File | Status | Blocked by | Files Modified |
|------|------|--------|-----------|---------------|
| {Task 1 name} | [task-1.md](task-1.md) | Done | -- | src/auth/*.rs |
| {Task 2 name} | [task-2.md](task-2.md) | In progress | task-1.md | -- |
| {Task 3 name} | [task-3.md](task-3.md) | Blocked | task-1.md, task-2.md | -- |
| **Fix login redirect** | *inline* | Not started | -- | -- |
| **Add created_at to users** | *inline* | Not started | -- | -- |

## Inline Tasks

- [ ] **Fix login redirect** — Update auth/redirect.rs. Verify: `cargo test auth`
- [ ] **Add created_at to users** — Add migration + field. Verify: `sqlx migrate run`

<!-- Optional: add a mermaid dependency graph only if the group has
     complex non-linear dependencies (5+ tasks with branching). -->

Cross-group dependencies:
- task-3 requires [../ui/explorer.md](../ui/explorer.md) (optional)
```

**Note:** Keep group overview.md scannable -- if you have to scroll, it's too long. Status table + inline tasks + optional mermaid. No prose.

### Template: `docs/ref/overview.md` (reference entry point)

```markdown
# Reference Overview

> Read this only when a task doc's Context Scope says "Read: docs/ref/..."
> Not read by default.

| Doc | When to read |
|-----|-------------|
| [requirements.md](requirements.md) | Defining new features, validating scope |
| [roadmap.md](roadmap.md) | Planning releases, checking milestones |
| [lessons.md](lessons.md) | After corrections, or at session start for your domain |
```

### Template: `docs/tasks/TEMPLATE.md` (task doc)

```markdown
# {Task Name}

**Blocked by:** {task name with relative path, or "none"}
**Group:** {group folder name}

## Context Scope

Read: {docs/arch/backend.md, specific file paths, or section references}
Ignore: {everything else, or specific areas to skip}

## Tools & Environment

> Include only the lines relevant to this task. Delete unused lines.

- **MCP servers:** {server names this task needs, e.g. firebase, dart, neo4j -- or "none"}
- **CLI tools:** {commands the agent should use, e.g. cargo test, npm run build, docker compose up}
- **Agent type:** {subagent type for execution, e.g. shell, browser-use, generalPurpose -- or "default"}
- **Browser:** {Yes -- URL to verify, e.g. http://localhost:3001 | No}
- **Scripts:** {project-specific scripts to use, e.g. ./restart.sh, ./scripts/seed-db.sh -- or "none"}
- **Env vars:** {required environment variables, e.g. NEO4J_URI=bolt://localhost:7687 -- or "none"}

## What / Why

{3-5 lines: what this task does, why it exists, what is in/out of scope.}

## Steps

> **Acceptance criteria are mandatory.** Every step must have a Verify command and Expected outcome. Do not add a step without both.

1. [ ] {Step title}
   - {What to do}
   - Verify: `{command}`
   - Expected: {what success looks like}

2. [ ] {Step title}
   - {What to do}
   - Verify: `{command}`
   - Expected: {what success looks like}

{Add more steps as needed. For complex tasks, group into phases.}

## Notes

- Arch impact: {docs/arch/X.md, or "none"}
- Estimated effort: {small / medium / large}

## Files Modified

(Filled on completion. List every file created, modified, or deleted.)

- `path/to/file` — what changed
```

For a detailed usage guide on the Tools & Environment fields, see [project_setup_enterprise.md](project_setup_enterprise.md#tools--environment-usage-guide). Most tasks will only need 1-2 of these fields. Delete the rest to keep the doc lean.

### Template: `docs/ref/lessons.md`

```markdown
# Lessons Learned

> Corrections log. After any user correction, add an entry below.
> When a pattern recurs (2+ times), promote it to an Active Lesson
> in `.cursor/rules/project.mdc` so it is auto-loaded every session.

## Lessons

| Date | What happened | Rule | Promoted? |
|------|--------------|------|-----------|
| | | | |
```

### Template: `docs/arch/TEMPLATE.md`

```markdown
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

{Describe or diagram the key data flows for this domain.
Use mermaid if helpful, plain text if simple.}

## API Surface (if applicable)

{Endpoints, tool interfaces, or public APIs this domain exposes.}
```

---

## Setup Script

The setup script creates all folders, templates, and overview.md files. It lives alongside this document.

**Run from the project root:**

```bash
bash project_setup.sh
```

See [project_setup.sh](project_setup.sh) for the full script. It creates:

- `.cursor/rules/project.mdc` (agent entry point)
- `docs/arch/overview.md` + `TEMPLATE.md`
- `docs/tasks/overview.md` + `TEMPLATE.md` + `GROUP_OVERVIEW_TEMPLATE.md`
- `docs/ref/overview.md` + `lessons.md` + `requirements.md` + `roadmap.md`
- `docs/validate.sh` (overview sync checker)

---

## Agent Instructions: How to Use This on a New Project

When a user says "Set up this project using project_setup.md":

1. **Run the setup script** (or create files manually if no shell access):
   - Creates `.cursor/rules/project.mdc`, all `overview.md` files, templates, and `docs/ref/` files

2. **Fill in `project.mdc`** with the user's project details:
   - Project name and description
   - Tech stack (ask the user if not obvious from the codebase)
   - Run `tree -L 2` or inspect the repo to fill project structure
   - Determine build/test/lint/run commands from package.json, Cargo.toml, Makefile, etc.

3. **Create initial arch docs** and update `docs/arch/overview.md`:
   - One `docs/arch/{domain}.md` per major component (backend, frontend, database, etc.)
   - Use the arch template; fill from existing code, README, or user input
   - Keep each under 200 lines
   - Add a row to `docs/arch/overview.md` for each domain doc created
   - When a domain outgrows 200 lines, split into `docs/arch/{domain}/overview.md` + sub-docs

4. **Create task groups when work begins:**
   - Create `docs/tasks/{group}/` subfolder for each domain (e.g., `backend/`, `ui/`)
   - Copy `GROUP_OVERVIEW_TEMPLATE.md` -> `docs/tasks/{group}/overview.md`
   - Copy `TEMPLATE.md` -> `docs/tasks/{group}/{task-name}.md` per task
   - Add a row to `docs/tasks/overview.md` for the new group

5. **Managing task dependencies:**
   - **Within a group:** Use task file names in the "Blocked by" field (e.g., `graph-schema.md`)
   - **Cross-group:** Use relative paths (e.g., `../backend/sync-branch.md`)
   - **Group overview.md** must reflect current status and dependency graph
   - **Top-level overview.md** must reflect cross-group blocking status
   - Before starting a task, check its "Blocked by" -- if the prerequisite's status is not Done, do not start
   - After completing a task, update its status in the group overview.md (the single source of truth for status)

6. **Scaling a section:**
   - When any `overview.md` gets too long (>30 lines), split its content into sub-files and keep the overview as a thin router
   - When a single-file arch doc exceeds 200 lines, convert to a folder: `backend.md` -> `backend/overview.md` + sub-docs
   - Update the parent overview.md to point to the new path -- nothing else changes

7. **Clean up if migrating from an existing system:**
   - If there are existing architecture/workflow docs, consolidate into the new structure
   - Remove redundant docs (agent guides, task workflows that duplicate cursor rules)
   - Flatten any plan/task hierarchies into `docs/tasks/{group}/`
   - Preserve dependency information from old plan READMEs into new group overview.md files

8. **Verify the setup:**
   - Confirm `.cursor/rules/project.mdc` exists and has `alwaysApply: true`
   - Confirm `docs/arch/overview.md` exists and lists at least one domain
   - Confirm `docs/tasks/overview.md` exists
   - Confirm `docs/tasks/TEMPLATE.md` exists
   - Confirm `docs/ref/overview.md` exists
   - Confirm `docs/ref/lessons.md` exists

---

## Scaling

For enterprise patterns (task archive, cross-cutting groups, domain-scoped lessons,
concurrent agent branching), see [project_setup_enterprise.md](project_setup_enterprise.md).
Activate these when you hit the thresholds described there.

---

## Design Principles (Why This Works)

1. **overview.md everywhere** — Every folder has an `overview.md`. Agent always reads it first. It either IS the content or routes to sub-docs. This one convention handles simple projects and enterprise monoliths with the same navigation pattern.
2. **Scales independently** — Any section can grow from a single file to a deep folder tree. Only the parent overview.md changes. The cursor rule, agent rules, and navigation pattern stay the same.
3. **Single entry point** — The cursor rule IS the project context. It points to three overview.md files. No chain of docs, no routing table that grows with the project.
4. **Context scoping** — Each task doc says "Read X. Ignore Y." at the top.
5. **Light grouping** — Tasks grouped by domain (2 levels max). Each group has a tiny overview.md with status + dependency graph.
6. **Dependency tracking** — Group overview.md status table and "Blocked by" column are the primary dependency tracker. An optional mermaid graph can be added for complex non-linear groups. Top-level overview.md shows cross-group blocking. Task docs have "Blocked by" for explicit prerequisites.
7. **Acceptance criteria mandatory** — Every task and every step must have a Verify command and Expected outcome. No separate acceptance file; criteria are embedded per step. Do not mark a task complete without passing verification.
8. **Lessons that enforce** — Recurring lessons become cursor rules (auto-loaded), not a file the agent might skip.
9. **Grow organically** — Start with project.mdc and 1 arch doc. Add domains, groups, and sub-docs as the project grows. No upfront ceremony, no structural rewrites.
