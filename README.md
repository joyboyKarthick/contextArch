# ContextArch

**Context architecture for AI-agent-driven development.**

Stop repeating yourself to AI agents. Stop drowning them in docs. Give them exactly what they need, when they need it.

---

## The Problem

If you build software with AI agents (Cursor, Claude, Copilot), you've hit these walls:

**Context repetition.** Every new session, you re-explain the tech stack, project structure, and architecture. The agent burns 30% of its context window before writing a single line of code.

**Context rot.** You've accumulated 20-40 markdown files. Architecture docs, task plans, implementation guides, acceptance criteria, agent workflows, lessons learned. Most are irrelevant to the current task. The agent reads them all anyway.

**Navigation chains.** Your cursor rule points to a workflow doc, which points to an agent guide, which points to the architecture doc, which indexes 4 split docs, which link to plan folders, which contain task docs. 6-8 file reads of pure overhead.

**Stale instructions.** Agent behavior rules live in 3 places. They drift out of sync. The agent follows whichever it reads last.

---

## The Solution

One system. One convention. **Every folder has an `overview.md` -- the agent always reads it first.**

```
your-project/
  .cursor/rules/
    project.mdc                       Tier 0: auto-loaded every session (~80 lines)
  docs/
    arch/
      overview.md                     Tier 1 entry: routes to the right domain doc
      backend.md                      Simple domain = single file
      payments/
        overview.md                   Complex domain = folder with sub-docs
        processing.md
        billing.md
    tasks/
      overview.md                     Tier 2 entry: all groups + cross-group status
      backend/
        overview.md                   Group: status + dependency graph
        add-product-crud.md           Task: steps + verification + context scope
    ref/
      overview.md                     Tier 3 entry: what reference docs exist
      requirements.md
      lessons.md
```

### What the agent reads per session

| File | Lines | Purpose |
|------|-------|---------|
| `project.mdc` | ~80 | Auto-loaded: identity, commands, rules |
| `docs/arch/overview.md` | ~25 | Find the right domain doc |
| `docs/arch/backend.md` | ~150 | Architecture for this task's domain |
| `docs/tasks/backend/overview.md` | ~20 | Task status + dependencies |
| Task doc | ~50 | Steps, verification, tools |
| **Total** | **~325** | **Down from 2000+** |

---

## Quick Start

1. Clone this repo (or just grab `project_setup.md` + `project_setup.sh`)
2. Open your project in Cursor
3. Tell the agent:

> *"Set up this project using project_setup.md. Project name is X, tech stack is Y."*

The agent creates the folder structure, fills in your project details, and you're ready. Takes ~2 minutes.

Every session after that starts with full context already loaded. Zero repetition. Zero navigation overhead.

---

## What's in This Repo

| File | For whom | Purpose |
|------|----------|---------|
| [`project_setup.md`](project_setup.md) | **The AI agent** | Architecture explanation, all templates, agent instructions. Load this into your agent. |
| [`project_setup.sh`](project_setup.sh) | **The AI agent** | Setup script that creates the folder structure and template files. Run by the agent during setup. |
| [`project_setup_enterprise.md`](project_setup_enterprise.md) | **The AI agent** | Enterprise scaling patterns (task archive, cross-cutting groups, domain-scoped lessons, concurrent branching). Referenced when needed. |
| [`README.md`](README.md) | **You** | This file. Explains what ContextArch is and how to use it. |

---

## How It Works

### Tier 0: `.cursor/rules/project.mdc` (auto-loaded)

The single entry point. Cursor loads this every session automatically. Contains project identity (name, tech stack, structure), build/test/lint commands, navigation pointers to the three overview.md files, agent behavioral rules, and active lessons.

**No routing table.** The cursor rule says "read `docs/arch/overview.md`" -- the overview handles routing. The cursor rule stays ~80 lines forever, regardless of how many domains the project has.

### Tier 1: `docs/arch/` (per-domain architecture)

`docs/arch/overview.md` lists all domains and points the agent to the right doc.

- **Simple domain:** Single file (`backend.md`, 100-200 lines)
- **Complex domain:** Folder with its own `overview.md` + sub-docs (`payments/overview.md` -> `processing.md`, `billing.md`)
- **Growing domain:** When a file exceeds 200 lines, split it into a folder. Update the parent overview.md. Nothing else changes.

### Tier 2: `docs/tasks/` (grouped by domain)

`docs/tasks/overview.md` lists all task groups and cross-group blocking status.

Each group has `overview.md` (status table + inline tasks + optional dependency graph) and task docs. Small 1-2 step tasks live inline in the group overview; larger tasks get their own file. Each task doc includes:

- **Context Scope** -- "Read X. Ignore Y." (prevents the agent from reading irrelevant docs)
- **Tools & Environment** -- MCP servers, CLI tools, agent type, browser URLs, scripts, env vars
- **Steps with verification** -- each step has a verify command and expected output
- **Blocked by** -- explicit dependency on other tasks (using `filename.md` format)
- **Files Modified** -- filled on completion as an audit trail

### Tier 3: `docs/ref/` (on-demand reference)

Requirements, roadmap, lessons. Only read when a task doc explicitly says to.

---

## Walkthrough

You're building **ShopAPI** -- Rust backend, React dashboard, PostgreSQL.

**Setup:** Agent creates `project.mdc`, overview.md files, templates.

**Architecture:** Agent creates `docs/arch/backend.md`, `database.md`, `ui.md` and lists them in `docs/arch/overview.md`.

**First task:** You say "Add product catalog CRUD." Agent creates:

```markdown
# Product Catalog CRUD

**Blocked by:** none
**Group:** backend

## Context Scope

Read: docs/arch/backend.md, docs/arch/database.md
Ignore: docs/arch/ui.md, everything in docs/ref/

## Tools & Environment

- **CLI tools:** cargo test, sqlx migrate run
- **Env vars:** DATABASE_URL=postgres://localhost/shopapi

## Steps

1. [ ] Add Product model and migration
   - Verify: `sqlx migrate run && sqlx migrate info`
   - Expected: Migration applied, products table exists

2. [ ] Add product repository (CRUD functions)
   - Verify: `cargo test repo::products`

3. [ ] Add REST endpoints (POST/GET/PUT/DELETE /api/products)
   - Verify: `cargo test routes::products`

## Files Modified

(Filled on completion.)
```

**6 months later:** 12 domains, 80+ tasks. The cursor rule is still ~80 lines. `payments/` split into sub-docs. Completed tasks archived. Domain-scoped lessons auto-load via cursor rule globs. Nothing was restructured.

---

## Enterprise Scaling

The base system handles solo and small-team projects out of the box. For larger projects, [`project_setup_enterprise.md`](project_setup_enterprise.md) includes 4 additive patterns -- activate when you hit the threshold, ignore until then:

| Pattern | Activate when | What it does |
|---------|--------------|--------------|
| **Task Archive** | 15+ tasks in a group | Move completed tasks to `archive/`, keep overview lean |
| **Cross-Cutting Group** | Task spans 3+ domains | Dedicated `cross-cutting/` task group with affected-domains field |
| **Domain-Scoped Lessons** | 15+ lessons accumulated | Glob-scoped `.mdc` rules that auto-load only for relevant file paths |
| **Concurrent Agent Branching** | 2+ agents working simultaneously | Branch-per-task convention, overview.md updated only on merge to main |

None require restructuring the base system.

---

## Before / After

From the real project where this system was developed:

| Dimension | Before | After |
|---|---|---|
| Context per session | ~2000 lines (8-9 files) | ~350 lines (3-4 files) |
| Agent instruction sources | 3 redundant files | 1 cursor rule |
| Navigation depth | 3 levels | 1-2 levels |
| Architecture entry point | 530-line monolith | 25-line overview + domain docs |
| Adding a new domain | Edit cursor rule + monolith doc | Add file + 1 row in overview.md |
| Acceptance criteria | 2 competing systems | Embedded per-step in task doc |
| Context scoping | None | Explicit "Read / Ignore" per task |

---

## The `overview.md` Convention

The entire system rests on one rule: **every folder has an `overview.md` that the agent reads first.**

For small sections, it IS the content:

```markdown
# Reference Overview

| Doc | When to read |
|-----|-------------|
| requirements.md | Defining new features |
| roadmap.md | Planning releases |
```

For large sections, it's a thin router:

```markdown
# Architecture Overview

| Domain | Doc | Structure | Description |
|--------|-----|-----------|-------------|
| Backend | backend.md | Single file | REST API |
| Payments | payments/overview.md | Sub-folder | Processing, billing, compliance |
```

When a section grows, split the file into a folder with its own overview.md. Only the parent overview.md gets a path update. The cursor rule, agent rules, and every other doc stay untouched.

This is how the system scales from a weekend project to an enterprise monolith without a rewrite.

---

## License

Apache 2.0